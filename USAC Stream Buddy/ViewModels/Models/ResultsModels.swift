//
//  ResultsViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/14/25.
//

import Foundation

// Common interface for ascent types in different disciplines
protocol AscentRepresentable: Codable {
    var routeID: Int { get }
    var routeName: String { get }
    var status: String { get }
}


// MARK: - Models for decoding the `ranking` key
struct RankingEntry<Ascent: Codable>: Codable, Identifiable {
    // Use athlete_id as a stable identifier
    var id: Int { athleteID }

    let athleteID: Int
    let name: String
    let firstname: String
    let lastname: String
    let bib: String
    let rank: Int
    let score: String
    let ascents: [Ascent]
    let active: Bool
    let underAppeal: Bool

    enum CodingKeys: String, CodingKey {
        case athleteID = "athlete_id"
        case name
        case firstname
        case lastname
        case bib
        case rank
        case score
        case ascents
        case active
        case underAppeal = "under_appeal"
    }
}


/*
"route_id":65681,
"route_name":"1",
"top":true,
"plus":false,
"rank":1,
"corrective_rank":6.0,
"score":"TOP",
"status":"confirmed",
"top_tries":null
 */
struct LeadAscent: AscentRepresentable {
    let routeID: Int
    let routeName: String
    let top: Bool
    let plus: Bool
    let rank: Int
    let correctiveRank: Int
    let score: String
    let status: String
    let topTries: Int?

    enum CodingKeys: String, CodingKey {
        case routeID = "route_id"
        case routeName = "route_name"
        case top
        case plus
        case rank
        case correctiveRank = "corrective_rank"
        case score
        case status
        case topTries = "top_tries"

    }
}

struct BoulderAscent: AscentRepresentable {
    let routeID: Int
    let routeName: String
    let top: Bool
    let topTries: Int?
    let zone: Bool
    let zoneTries: Int?
    let lowZone: Bool
    let points: Double
    let lowZoneTries: Int?
    let modified: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case routeID = "route_id"
        case routeName = "route_name"
        case top
        case topTries = "top_tries"
        case zone
        case zoneTries = "zone_tries"
        case lowZone = "low_zone"
        case points
        case lowZoneTries = "low_zone_tries"
        case modified
        case status
    }
}

// Concrete typealiases for common ranking entry usages
// Use these when decoding lead and bouldering result lists
 typealias LeadRankingEntry = RankingEntry<LeadAscent>
 typealias BoulderRankingEntry = RankingEntry<BoulderAscent>

// Convenience wrappers for decoding full responses per discipline
struct LeadEventResultsResponse: Codable {
    let ranking: [LeadRankingEntry]
}

struct BoulderEventResultsResponse: Codable {
    let ranking: [BoulderRankingEntry]
}

