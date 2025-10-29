//
//  EventDetailsView.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/22/25.
//

import SwiftUI

struct EventDetailsView: View {
    @State private var viewModel: ResultViewModel
    
    init(event: Event) {
        viewModel = ResultViewModel(event: event, round: .final)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Round", selection: $viewModel.selectedRound) {
                    ForEach(Round.allCases, id: \.self) { round in
                        Text(round.rawValue).tag(round)
                    }
                }
            }
            Section {
                Button("Start Timer") {
                    viewModel.processData()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
    }
}

#Preview {
    EventDetailsView(event: .init(name: "Something", categories: []))
}
