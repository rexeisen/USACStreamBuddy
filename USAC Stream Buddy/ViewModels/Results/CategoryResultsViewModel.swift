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

        return try await genericOnWallResponse(result: result)
    }
    
    private func handleLeadResponse(data: Data) async throws -> [OnWall] {
        let result: GenericEventResultsResponse = try decoder.decode(
            GenericEventResultsResponse<LeadAscent>.self,
            from: data
        )

        return try await genericOnWallResponse(result: result)
    }
    
    func genericOnWallResponse<T: AscentRepresentable>(result: GenericEventResultsResponse<T>) async throws -> [OnWall] {
        
        var onWall: [OnWall] = []

        // Go through each route and find the item that is active
        for route in categoryRound.routes {
            let currentlyActive = result.sorted(
                routeId: route.id,
                status: .active
            )

            let parsedKey = categoryRound.category + route.name

            if let lastActive = currentlyActive.last {
                onWall.append(
                    .init(route: parsedKey, name: lastActive.description)
                )
            } else {
                // Get the next person from the startlist
                // Step one is to get the last confirmed
                let currentlyActive = result.sorted(
                    routeId: route.id,
                    status: .confirmed
                )

                if let lastConfirmed = currentlyActive.last,
                    let startIndex = result.startlist.firstIndex(where: {
                        $0.bib == lastConfirmed.bib
                    })
                {
                    // Get the person after the last active
                    if startIndex + 1 < result.startlist.count {
                        let athlete = result.startlist[startIndex + 1]
                        onWall.append(
                            .init(route: parsedKey, name: athlete.description)
                        )
                    }

                } else if let athlete = result.startlist.first {
                    // Get the first person in the start list
                    onWall.append(
                        .init(route: parsedKey, name: athlete.description)
                    )
                }
            }
        }

        return onWall
    }
}
