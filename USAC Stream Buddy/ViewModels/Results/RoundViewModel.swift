//
//  RoundViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/21/25.
//

import Foundation
import Combine

@Observable
final class RoundViewModel {
    var selectedRound: Round = .final
    private var event: Event
    private(set) var resultURLRequests: [URLRequest] = []
    
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
    
    func startTimer() {
    }
}

