//
//  EventModels.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/14/25.
//

import Foundation

// MARK: - Models
// Root listing for the season response containing events and other metadata.
struct EventListing: Codable {
    let name: String
    let events: [EventSummary]
}

// Minimal event summary used by the UI
struct EventSummary: Codable, Identifiable, Equatable {
    let event: String
    let event_id: Int
    let url: String
    let starts_at: Date

    // Provide a stable id for SwiftUI Lists
    var id: Int { event_id }

    private static let startsAtFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        return df
    }()

    enum CodingKeys: String, CodingKey { case event, event_id, url, starts_at }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.event = try container.decode(String.self, forKey: .event)
        self.event_id = try container.decode(Int.self, forKey: .event_id)
        self.url = try container.decode(String.self, forKey: .url)
        let startsAtString = try container.decode(String.self, forKey: .starts_at)
        guard let date = EventSummary.startsAtFormatter.date(from: startsAtString) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.starts_at], debugDescription: "Invalid starts_at format: \(startsAtString)"))
        }
        self.starts_at = date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encode(event_id, forKey: .event_id)
        try container.encode(url, forKey: .url)
        let dateString = EventSummary.startsAtFormatter.string(from: starts_at)
        try container.encode(dateString, forKey: .starts_at)
    }
}
