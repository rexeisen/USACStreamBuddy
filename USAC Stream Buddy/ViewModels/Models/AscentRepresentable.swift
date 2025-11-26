//
//  AscentRepresentable.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 11/21/25.
//

import Foundation

// Common interface for ascent types in different disciplines
protocol AscentRepresentable: Codable {
    var routeID: Int { get }
    var routeName: String { get }
    var status: AscentStatus { get }
    var modified: Date { get }
}

extension AscentRepresentable {
    var modified: Date {
        Date(timeIntervalSinceReferenceDate: 0)
    }
}
