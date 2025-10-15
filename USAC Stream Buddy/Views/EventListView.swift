//
//  EventListView.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/7/25.
//

import SwiftUI

struct EventListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = EventListViewModel()
    @State private var searchText = ""

    // Callback when an event is selected
    var onSelect: (EventSummary) -> Void = { _ in }

    var filteredEvents: [EventSummary] {
        let events = viewModel.events
        guard !searchText.isEmpty else { return events }
        return events.filter { $0.event.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading events…")
            case .failed(let error):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
                    Text("Failed to load events")
                    Text(error.localizedDescription).font(.footnote).foregroundStyle(.secondary)
                    Button("Retry") { Task { await viewModel.load() } }
                }
                .padding()
            case .loaded:
                List(filteredEvents) { event in
                    Button {
                        onSelect(event)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.event)
                                .font(.headline)
                            Text(Self.dateFormatter.string(from: event.starts_at))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
#if os(iOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
#else
        .searchable(text: $searchText)
#endif
        .navigationTitle("Events")
        .task { await viewModel.load() }
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
}

#Preview {
    NavigationStack { EventListView(onSelect: { _ in }) }
        .frame(width: 500, height: 500)
}
