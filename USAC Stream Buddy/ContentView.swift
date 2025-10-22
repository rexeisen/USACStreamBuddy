//
//  ContentView.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/7/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingEvents = false
    @State private var viewModel = EventViewModel()
    
    
    var body: some View {
        VStack(spacing: 20) {
            switch viewModel.state {
            case .idle:
                Text("No event selected")
                    .foregroundStyle(.secondary)
            case .loading:
                ProgressView("Loading event…")
            case .loaded(let event):
                VStack(spacing: 8) {
                    Text("Selected Event:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(event.name)
                        .font(.title2)
                        .bold()
                }
            case .failed(let error):
                VStack(spacing: 8) {
                    Text("Failed to load event")
                    Text(error.localizedDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Choose Event") { showingEvents = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .sheet(isPresented: $showingEvents) {
            NavigationStack {
                EventListView { summary in
                    // Set the selected id and start loading
                    viewModel.eventId = summary.event_id
                    Task { await viewModel.load() }
                }
                .navigationTitle("Events")
                #if os(iOS) || os(visionOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            }
            // Size the sheet content to 500x500 and, on macOS, fit the window to content
            .frame(width: 500, height: 500)
            #if os(macOS)
            .presentationSizing(.fitted)
            #endif
        }
    }
}

#Preview {
    ContentView()
}
