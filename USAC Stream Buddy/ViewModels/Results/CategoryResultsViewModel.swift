//
//  CategoryResultsViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 11/2/25.
//

import Combine
import Foundation

@Observable
final class CategoryResultsViewModel {
    let categoryRound: CategoryRound
    private let decoder = JSONDecoder()

    @ObservationIgnored
    private var timer: Timer?

    @ObservationIgnored
    private var isFetching: Bool = false
    
    init(categoryRound: CategoryRound) {
        self.categoryRound = categoryRound

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd HH:mm:ss XXX"
        decoder.dateDecodingStrategy = .formatted(df)
        
    }

    deinit {
        stopTimer()
    }

    func startTimer() {
        stopTimer()
        // Schedule a repeating 5-second timer on the main run loop
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
            [weak self] _ in
            if let self = self { Task { await self.fetch() } }
        }
        // Fire immediately once
        Task { await self.fetch() }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func fetch() async {
        guard let request = try? URLEndpoint.results(categoryRound.id).url()
        else {
            stopTimer()
            return
        }
        
        // Prevent overlapping fetch cycles if one is still in progress
        if isFetching { return }
        isFetching = true

        do {
            // Using async/await API for URLSession
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            
            guard let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode)
            else {
                throw URLError(.badServerResponse)
            }

            let discipline = self.categoryRound.discipline
            if discipline == .boulder {
                _ = try await self.handleBoulderingResponse(data: data)
            } else if discipline == .lead {
                try await self.handleLeadResponse(data: data)
            }

            // Handle data/response as needed
        } catch {
            // Handle error as needed (log, retry, etc.)
            stopTimer()
            print("Error fetching results: \(error)")
        }

        // Reset fetching state on the main actor
        isFetching = false
    }

    func handleBoulderingResponse(data: Data) async throws -> [OnWall] {
        let result: GenericEventResultsResponse = try decoder.decode(
            GenericEventResultsResponse<BoulderAscent>.self,
            from: data
        )

        var onWall: [OnWall] = []
        
        let rankings = result.ranking
        // Go through each route and find the item that is active
        for route in categoryRound.routes {
            var currentlyActive = rankings.filter {
                $0.ascent(routeId: route.id, status: "active") != nil
            }
            
            // We now want to sort these currently active routes by
            // the ascent modified date
            currentlyActive.sort { lhs, rhs in
                let lAsc = lhs.ascent(routeId: route.id, status: "active")
                let rAsc = rhs.ascent(routeId: route.id, status: "active")

                switch (lAsc, rAsc) {
                case let (l?, r?):
                    return l.modified < r.modified
                case (nil, nil):
                    return false
                case (_, nil):
                    return true
                case (nil, _):
                    return false
                }
            }
            
            let parsedKey = categoryRound.category + route.name
            
            if let lastActive = currentlyActive.last {
                let value = "#\(lastActive.bib) \(lastActive.name)"
                onWall.append(.init(route: parsedKey, name: value))
            } else {
                // Get the next person from the startlist
                // Step one is to get the last confirmed

                var currentlyActive = rankings.filter {
                    $0.ascent(routeId: route.id, status: "confirmed") != nil
                }
                
                // We now want to sort these currently active routes by
                // the ascent modified date
                currentlyActive.sort { lhs, rhs in
                    let lAsc = lhs.ascent(routeId: route.id, status: "confirmed")
                    let rAsc = rhs.ascent(routeId: route.id, status: "confirmed")

                    switch (lAsc, rAsc) {
                    case let (l?, r?):
                        return l.modified < r.modified
                    case (nil, nil):
                        return false
                    case (_, nil):
                        return true
                    case (nil, _):
                        return false
                    }
                }
                
                if let lastConfirmed = currentlyActive.last, let startIndex = result.startlist.firstIndex(where: { $0.bib == lastConfirmed.bib }) {
                    // Get the person after the last active
                    if startIndex + 1 < result.startlist.count {
                        let athlete = result.startlist[startIndex + 1]
                        let value = "#\(athlete.bib) \(athlete.name)"
                        onWall.append(.init(route: parsedKey, name: value))
                    }
                    
                } else if let athlete = result.startlist.first {
                    // Get the first person in the start list
                    let value = "#\(athlete.bib) \(athlete.name)"
                    onWall.append(.init(route: parsedKey, name: value))
                }
            }
        }

        return onWall
    }

    private func handleLeadResponse(data: Data) async throws {
        //        let result = try decoder.decode(
        //            LeadEventResultsResponse.self,
        //            from: data
        //        )
    }
    
    private func sortedData<T: AscentRepresentable>(result: GenericEventResultsResponse<T>, route: Route, key: String) -> [RankingEntry<T>]  {
        []
//        var currentlyActive = result.ranking.filter {
//            $0.ascent(routeId: route.id, status: key) != nil
//        }
//        
//        // We now want to sort these currently active routes by
//        // the ascent modified date
//        currentlyActive.sort { lhs, rhs in
//            let lAsc = lhs.ascent(routeId: route.id, status: key)
//            let rAsc = rhs.ascent(routeId: route.id, status: key)
//
//            switch (lAsc, rAsc) {
//            case let (l?, r?):
//                return l.modified < r.modified
//            case (nil, nil):
//                return false
//            case (_, nil):
//                return true
//            case (nil, _):
//                return false
//            }
//        }
//        return currentlyActive
    }
}
