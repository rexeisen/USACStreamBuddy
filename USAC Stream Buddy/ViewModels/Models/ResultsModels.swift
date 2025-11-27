//
//  ResultsViewModel.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/14/25.
//

import Foundation

// MARK: - Models for decoding the `ranking` key
struct RankingEntry<Ascent: AscentRepresentable>: Codable, Identifiable,
    CustomStringConvertible
{
    var description: String { "#\(bib) \(name)" }

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

    func ascent(routeId: Int, status: AscentStatus? = nil) -> Ascent? {
        guard let ascent = self.ascents.first(where: { $0.routeID == routeId })
        else {
            return nil
        }

        if let status {
            if ascent.status == status {
                return ascent
            } else {
                return nil
            }
        } else {
            return ascent
        }
    }
    
    /// The representation of the ascents in TZL0P format
    var scoreRepresentation: String? {
        return ascents.compactMap{ $0.scoreRepresentation }.joined(separator: "")
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
    let rank: Int?
    let correctiveRank: Double
    let score: String
    let status: AscentStatus
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
    let modified: Date
    let status: AscentStatus

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
    
    var scoreRepresentation: String? {
        if top {
            return "T"
        } else if zone {
            return "Z"
        } else if lowZone {
            return "L"
        } else if status == .pending {
            return "P"
        } else {
            // Covers active or confirmed
            return "0"
        }
    }
}

struct GenericEventResultsResponse<T: AscentRepresentable>: Codable {
    let ranking: [RankingEntry<T>]
    let startlist: [StartListEntry]

    func sorted(routeId: Int, status: AscentStatus? = nil) -> [RankingEntry<T>] {
        var currentlyActive = self.ranking.filter {
            $0.ascent(routeId: routeId, status: status) != nil
        }
                
        // If this is a Lead event, do not sort; return the filtered list as-is
        if T.self == LeadAscent.self {
            // Lead doesn't have a proper modified date so sort by start list
            let sortedStartList = self.startlist.sorted { lhs, rhs in
                let lhsPosition: Int = lhs.startPositions.filter { $0.routeId == routeId }.first?.position ?? 0
                let rhsPosition: Int = rhs.startPositions.filter { $0.routeId == routeId }.first?.position ?? 0
                
                return lhsPosition < rhsPosition
            }
            
            currentlyActive.sort { lhs, rhs in
                let lIndex = sortedStartList.firstIndex(where: { $0.bib == lhs.bib })
                let rIndex = sortedStartList.firstIndex(where: { $0.bib == rhs.bib })
                
                switch (lIndex, rIndex) {
                case let (l?, r?):
                    return l < r
                case (nil, nil):
                    return false
                case (_, nil):
                    return true
                case (nil, _):
                    return false
                }
            }
        } else {
            // We now want to sort these currently active routes by
            // the ascent modified date
            currentlyActive.sort { lhs, rhs in
                let lAsc = lhs.ascent(routeId: routeId, status: status)
                let rAsc = rhs.ascent(routeId: routeId, status: status)

                switch (lAsc, rAsc) {
                case let (l?, r?):
                    return l.modified < r.modified
                case (nil, nil):
                    return false
                case (_, nil):
                    return true
                case (nil, _):
                    return false
                }
            }
        }
        
        return currentlyActive
    }
}

/*
 "route_start_positions":[
             {
                "route_name":"1",
                "route_id":65681,
                "position":30
             },
             {
                "route_name":"2",
                "route_id":65682,
                "position":10
             },
             {
                "route_name":"3",
                "route_id":65683,
                "position":20
             }
          ],
 */

struct StartListEntry: Identifiable, Codable, CustomStringConvertible {
    var description: String { "#\(bib) \(name)" }

    let id: Int
    let bib: String
    let name: String
    let startPositions: [StartListRoutePosition]
    
    enum CodingKeys: String, CodingKey {
        case id = "athlete_id"
        case bib
        case name
        case startPositions = "route_start_positions"
    }
}

struct StartListRoutePosition: Identifiable, Codable {
    let id: String
    let routeId: Int
    let position: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "route_name"
        case routeId = "route_id"
        case position
    }
}
