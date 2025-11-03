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
        df.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
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
        guard let request = try? URLEndpoint.results(categoryRound.id).url() else {
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
                try await self.handleBoulderingResponse(data: data)
            } else if discipline == .lead {
                try await self.handleLeadResponse(data: data)
            }

            // Handle data/response as needed
        } catch {
            // Handle error as needed (log, retry, etc.)
            print("Error fetching results: \(error)")
        }

        // Reset fetching state on the main actor
        isFetching = false
    }

    private func handleBoulderingResponse(data: Data) async throws {
        let result = try decoder.decode(
            BoulderEventResultsResponse.self,
            from: data
        )

    }

    private func handleLeadResponse(data: Data) async throws {
        let result = try decoder.decode(
            LeadEventResultsResponse.self,
            from: data
        )
    }

}
