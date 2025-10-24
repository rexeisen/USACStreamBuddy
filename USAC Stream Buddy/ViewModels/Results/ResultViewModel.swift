//
//  ResultViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/21/25.
//

import Foundation
import Combine

@Observable
final class ResultViewModel {
    var selectedRound: Round = .final
    var onWall: [String: RankingEntry] = [:]
    var event: Event
    private(set) var resultURLs: [URL] = []
    private var timer: Timer?
    private var isFetching: Bool = false
    
    init(event: Event) {
        self.event = event
    }
    
    func processData() {
        // Build result URLs for each category in the event
//        var urls: [URL] = []
//        for category in event.categories {
//            // `URLEndpoint.results(category.id).url` is a throwing function returning URLRequest
//            if let request = try? URLEndpoint.results(category.rounds).url(),
//               let url = request.url {
//                urls.append(url)
//            }
//        }
//        self.resultURLs = urls
//        startTimer()
    }
    
    deinit {
        stopTimer()
    }

    func startTimer() {
        stopTimer()
        guard !resultURLs.isEmpty else { return }
        // Schedule a repeating 5-second timer on the main run loop
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            if let self = self { Task { await self.fetchAll() } }
        }
        // Fire immediately once
        Task { await self.fetchAll() }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @MainActor
    private func fetchAll() async {
        // Prevent overlapping fetch cycles if one is still in progress
        if isFetching { return }
        isFetching = true

        let urls = self.resultURLs

        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    do {
                        // Using async/await API for URLSession
                        
                        _ = try await URLSession.shared.data(from: url)
                        // Handle data/response as needed
                    } catch {
                        // Handle error as needed (log, retry, etc.)
                    }
                }
            }
            // Wait for all tasks to complete
            await group.waitForAll()
        }

        // Reset fetching state on the main actor
        isFetching = false
    }
}

