//
//  EventListViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/7/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class EventListViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded([EventSummary])
        case failed(Error)
    }

    private(set) var state: LoadState = .idle

    // Public convenience accessor for the decoded events if loaded
    var events: [EventSummary] {
        if case let .loaded(events) = state { return events }
        return []
    }

    // MARK: - API
    func load() async {
        state = .loading
        do {
            let request = try URLEndpoint.schedule.url()
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoder = JSONDecoder()
            let listing = try decoder.decode(EventListing.self, from: data)
            state = .loaded(listing.events)
        } catch {
            state = .failed(error)
        }
    }
}
