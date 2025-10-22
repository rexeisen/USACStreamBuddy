//
//  ResultViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/21/25.
//

import Foundation
import Combine

class ResultViewModel {
    var event: Event
    private(set) var resultURLs: [URL] = []
    private var timer: Timer?
    private var isFetching: Bool = false
    
    init(event: Event) {
        self.event = event
    }
    
    func processData() {
        // Build result URLs for each category in the event
        var urls: [URL] = []
        for category in event.categories {
            // `URLEndpoint.results(category.id).url` is a throwing function returning URLRequest
            if let request = try? URLEndpoint.results(category.id).url(),
               let url = request.url {
                urls.append(url)
            }
        }
        self.resultURLs = urls
        startTimer()
    }
    
    deinit {
        stopTimer()
    }

    func startTimer() {
        stopTimer()
        guard !resultURLs.isEmpty else { return }
        // Schedule a repeating 5-second timer on the main run loop
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchAll()
        }
        // Fire immediately once
        fetchAll()
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchAll() {
        // Prevent overlapping fetch cycles if one is still in progress
        if isFetching { return }
        isFetching = true
        let urls = self.resultURLs
        let group = DispatchGroup()

        for url in urls {
            group.enter()
            let task = URLSession.shared.dataTask(with: url) { _, _, _ in
                // Handle data/response/error as needed
                group.leave()
            }
            task.resume()
        }

        group.notify(queue: .main) { [weak self] in
            self?.isFetching = false
        }
    }
}
