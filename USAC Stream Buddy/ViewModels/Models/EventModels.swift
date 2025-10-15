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
    }

    let id: Int
    let name: String
    let status: String
}
