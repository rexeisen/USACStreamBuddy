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
    var selectedRound: Round = .final {
        didSet {
            categoryResults = []
        }
    }
    var selectedDiscipline: Discipline = .unknown {
        didSet {
            categoryResults = []
        }
    }
    private var event: Event
    private(set) var categoryResults: [CategoryResultsViewModel] = []
    var availableDisciplines: [Discipline]
    var availableRounds: [Round]
    
    init(event: Event, round: Round) {
        self.event = event
        self.selectedRound = round
        
        let disciplinesSet = Set(event.categories.compactMap{$0.discipline})
        self.availableDisciplines = Array(disciplinesSet).sorted(by: { $0.rawValue < $1.rawValue })
        
        let availableRoundsSet = Set(event.categories.flatMap(\.rounds).map(\.round)).compactMap(\.self)
        self.availableRounds = availableRoundsSet
        
        if let first = self.availableDisciplines.first {
            selectedDiscipline  = first
        }
        
        if let firstRound = self.availableRounds.first {
            selectedRound  = firstRound
        }
    }
    
    func processData() {
        // Build result URLs for each category in the event
        var categoryResults: [CategoryResultsViewModel] = []
        for category in event.categories {
            for round in category.rounds where round.round == selectedRound {
                if round.discipline == selectedDiscipline {
                    categoryResults.append(CategoryResultsViewModel(categoryRound: round))
                }
            }
        }
        self.categoryResults = categoryResults
    }
    
    func startTimer() {
        categoryResults.forEach { $0.startTimer() }
    }
    
    func stopTimer() {
        categoryResults.forEach { $0.stopTimer() }
    }
}

