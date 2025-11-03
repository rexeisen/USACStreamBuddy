//
//  RoundModels.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/14/25.
//

import Foundation

struct Event: Codable {
    enum CodingKeys: String, CodingKey {
        case categories = "d_cats"
        case name
    }

    let name: String
    let categories: [Category]
}

struct Category: Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "dcat_id"
        case name = "category_name"
        case status
        case discipline = "discipline_kind"
        case rounds = "category_rounds"
    }

    let id: Int
    let name: String
    let status: String
    let discipline: Discipline
    let rounds: [CategoryRound]
}

struct CategoryRound: Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id = "category_round_id"
        case round = "name"
        case status
        case discipline = "kind"
        case category
        case routes
    }

    let id: Int
    let discipline: Discipline
    let round: Round
    let status: String
    let category: String
    let routes: [Route]
}

struct Route: Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startListURL = "startlist"
        case rankingURL = "ranking"
    }
    
    let id: Int
    let name: String
    let startListURL: String
    let rankingURL: String
}
