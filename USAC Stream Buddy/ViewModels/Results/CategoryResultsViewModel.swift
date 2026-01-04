//
//  CategoryResultsViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 11/2/25.
//

import Combine
import Foundation

enum CategoryResultsViewModelError: Error {
    case unknownFormat
}

@Observable
final class CategoryResultsViewModel: Identifiable {
    let categoryRound: CategoryRound
    private let decoder = JSONDecoder()

    @ObservationIgnored
    private var timer: Timer?

    @ObservationIgnored
    private var isFetching: Bool = false
    
    var lastFetch: String
    
    var id: Int { categoryRound.id }

    init(categoryRound: CategoryRound) {
        print("\(URL.documentsDirectory)")
        self.categoryRound = categoryRound

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd HH:mm:ss XXX"
        decoder.dateDecodingStrategy = .formatted(df)

        lastFetch = "Never"
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
            let onWall: [OnWall]
            if discipline == .boulder {
                onWall = try await self.handleBoulderingResponse(data: data)
            } else if discipline == .lead {
                onWall = try await self.handleLeadResponse(data: data)
            } else {
                throw CategoryResultsViewModelError.unknownFormat
            }

            for athlete in onWall {
                athlete.commit()
            }
            
            // Reset fetching state on the main actor
            lastFetch = Date().formatted(date: .omitted, time: .standard)
        } catch {
            // Handle error as needed (log, retry, etc.)
            stopTimer()
            print("Error fetching results: \(error)")
            print("Request: \(request)")
            lastFetch = error.localizedDescription
        }

        isFetching = false
    }

    func handleBoulderingResponse(data: Data) async throws -> [OnWall] {
        let result: GenericEventResultsResponse = try decoder.decode(
            GenericEventResultsResponse<BoulderAscent>.self,
            from: data
        )

        return try await genericOnWallResponse(result: result)
    }

    func handleLeadResponse(data: Data) async throws -> [OnWall] {
        let result: GenericEventResultsResponse = try decoder.decode(
            GenericEventResultsResponse<LeadAscent>.self,
            from: data
        )

        return try await genericOnWallResponse(result: result)
    }

    func genericOnWallResponse<T: AscentRepresentable>(
        result: GenericEventResultsResponse<T>
    ) async throws -> [OnWall] {

        var onWall: [OnWall] = []
        
        // We need to deal with DNS / Scratch
        // Remove them from the start list
        var startlist = result.startlist
        let scratchList = result.ranking.filter {
            $0.score == "DNS"
        }
        for scratch in scratchList {
            startlist.removeAll { $0.bib == scratch.bib }
        }

        // Go through each route and find the item that is active
        
        // String of zeros with length equal to the number of routes
        let pendingString = String(repeating: "P", count: categoryRound.routes.count)

        for route in categoryRound.routes {
            let currentlyActive = result.sorted(
                routeId: route.id,
                status: .active
            )

            let parsedKey = categoryRound.category + route.name

            if let lastActive = currentlyActive.last {
                onWall.append(
                    .init(
                        route: parsedKey,
                        bib: lastActive.bib,
                        name: lastActive.name,
                        score: lastActive.scoreRepresentation
                    )
                )
            } else {
                // Get the next person from the startlist
                // Step one is to get the last confirmed                
                let currentlyPending = result.sorted(
                    routeId: route.id,
                    status: .pending
                )
                
                if let firstPending = currentlyPending.first,
                    let startIndex = startlist.firstIndex(where: {
                        $0.bib == firstPending.bib
                    }),
                    let ranking = result.ranking.first(where: {
                        $0.bib == startlist[startIndex].bib
                    })
                {
                    // Get the person after the last active
                    let athlete = result.startlist[startIndex]
                    // Get the ranking entry for the athlete
                    // for the score

                    onWall.append(
                        .init(
                            route: parsedKey,
                            bib: athlete.bib,
                            name: athlete.name,
                            score: ranking.scoreRepresentation
                        )
                    )

                } else if let athlete = startlist.first {
                    var scoreRepresentation: String? = pendingString

                    if let ranking = result.ranking.first(where: {
                        $0.bib == athlete.bib
                    }) {
                        scoreRepresentation = ranking.scoreRepresentation
                    }

                    // Get the first person in the start list
                    onWall.append(
                        .init(
                            route: parsedKey,
                            bib: athlete.bib,
                            name: athlete.name,
                            score: scoreRepresentation
                        )
                    )
                }
            }
        }

        return onWall
    }
}

