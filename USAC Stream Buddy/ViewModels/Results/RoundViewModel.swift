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
    private(set) var categoryResults: [CategoryResultsViewModel] = []
    
    private var discipline: Discipline = .unknown
    
    init(event: Event, round: Round) {
        self.event = event
        self.selectedRound = round
        
    }
    
    func processData() {
        // Build result URLs for each category in the event
        var categoryResults: [CategoryResultsViewModel] = []
        for category in event.categories {
            for round in category.rounds where round.round == selectedRound {
                if round.discipline == .boulder {
                    categoryResults.append(CategoryResultsViewModel(categoryRound: round))
                }
            }
        }
        self.categoryResults = categoryResults
        startTimer()
    }
    
    func startTimer() {
        categoryResults.forEach { $0.startTimer() }
    }
}

