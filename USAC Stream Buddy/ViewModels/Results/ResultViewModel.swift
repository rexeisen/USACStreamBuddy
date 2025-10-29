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
    private var event: Event
    private(set) var resultURLRequests: [URLRequest] = []
    private var timer: Timer?
    private var isFetching: Bool = false
    private var discipline: Discipline = .unknown
    
    init(event: Event, round: Round) {
        self.event = event
        self.selectedRound = round
    }
    
    func processData() {
        // Build result URLs for each category in the event
        var urls: [URLRequest] = []
        for category in event.categories {
            for round in category.rounds where round.round == selectedRound {
                if let request = try? URLEndpoint.results(round.id).url() {
                    discipline = round.discipline
                    if urls.isEmpty {
                        urls.append(request)
                    }
                }
                    
            }
        }
        self.resultURLRequests = urls
        startTimer()
    }
    
    deinit {
        stopTimer()
    }

    func startTimer() {
        stopTimer()
        guard !resultURLRequests.isEmpty else { return }
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

        let urlRequests = self.resultURLRequests

        await withTaskGroup(of: Void.self) { group in
            for request in urlRequests {
                group.addTask {
                    do {
                        // Using async/await API for URLSession
                        let (data, response) = try await URLSession.shared.data(for: request)
                        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                            throw URLError(.badServerResponse)
                        }
                        
                        let discipline = await self.discipline
                        try await self.handleResponse(data: data)
                                                                        
                        // Handle data/response as needed
                    } catch {
                        // Handle error as needed (log, retry, etc.)
                        print("Error fetching results: \(error)")
                    }
                }
            }
            // Wait for all tasks to complete
            await group.waitForAll()
        }

        // Reset fetching state on the main actor
        isFetching = false
    }
    
    private func handleResponse(data: Data) throws {
        let decoder = JSONDecoder()
        
        let rankings: [RankingEntry<AscentRepresentable>]
        if self.discipline == .boulder {
            let result = try decoder.decode(BoulderEventResultsResponse.self, from: data)
            rankings = result.ranking
        } else {
            let result = try decoder.decode(LeadEventResultsResponse.self, from: data)
            rankings = result.ranking
        }
        
        
        
    }
}

