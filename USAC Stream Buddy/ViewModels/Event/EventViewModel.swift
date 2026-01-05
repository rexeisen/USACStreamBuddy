//
//  EventViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/14/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class EventViewModel {
    enum LoadState {
        case idle
        case loading
        case loaded(Event)
        case failed(Error)
    }

    private(set) var state: LoadState = .idle

    var eventId: Int = -1
    
    // MARK: - API
    func load() async {
        state = .loading
        do {
            // 117 is the test event
            let request = try URLEndpoint.event(eventId).url()
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let decoder = JSONDecoder()
            let listing = try decoder.decode(Event.self, from: data)
            state = .loaded(listing)
        } catch {
            state = .failed(error)
        }
    }
}

