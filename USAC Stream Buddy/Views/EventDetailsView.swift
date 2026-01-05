//
//  EventDetailsView.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/22/25.
//

import SwiftUI

struct EventDetailsView: View {
    @State private var viewModel: RoundViewModel
    @State private var isTimerOn: Bool = false
    
    init(event: Event) {
        viewModel = RoundViewModel(event: event, round: .final)
    }

    var body: some View {
        Form {
            Section {
                Picker("Round", selection: $viewModel.selectedRound) {
                    ForEach(viewModel.availableRounds, id: \.self) { round in
                        Text(round.rawValue).tag(round)
                    }
                }
                Picker("Discipline", selection: $viewModel.selectedDiscipline) {
                    ForEach(viewModel.availableDisciplines, id: \.self) { selectedDiscipline in
                        Text(selectedDiscipline.rawValue).tag(selectedDiscipline)
                    }
                }
            }
            Section {
                Button("Load Round") {
                    viewModel.processData()
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Toggle(isOn: $isTimerOn) {
                    Text("Timer")
                }
                .onChange(of: isTimerOn) { _, newValue in
                    if newValue {
                        viewModel.startTimer()
                    } else {
                        viewModel.stopTimer()
                    }
                }
            }
            Section("Loaded Round") {
                if viewModel.categoryResults.isEmpty {
                    ContentUnavailableView(
                        "No category results loaded yet",
                        systemImage: "circle.dotted"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    // Table with rows: Category, Round, Last Updated
                    
                    Table(viewModel.categoryResults) {
                        TableColumn("Category", value: \.categoryRound.category)
                        TableColumn("Round", value: \.categoryRound.round.rawValue)
                        TableColumn("Last Fetched", value: \.lastFetch)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    EventDetailsView(event: .init(name: "Something", categories: []))
}
