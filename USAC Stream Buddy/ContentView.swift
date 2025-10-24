//
//  ContentView.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/7/25.
//

import Combine
import SwiftUI

struct ContentView: View {
    @State private var selection: EventSummary?
    @State private var viewModel = EventViewModel()

    var body: some View {
        NavigationSplitView {
            EventListView { summary in
                selection = summary
                                viewModel.eventId = summary.event_id
                                Task { await viewModel.load() }
            }
        } detail: {
            Group {
                switch viewModel.state {
                case .idle:
                    ContentUnavailableView(
                        "Select an event",
                        systemImage: "list.bullet"
                    )
                case .loading:
                    ProgressView("Loading event…")
                case .loaded(let event):
                    EventDetailsView(event: event)
                case .failed(let error):
                    VStack(spacing: 8) {
                        Text("Failed to load event")
                        Text(error.localizedDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
