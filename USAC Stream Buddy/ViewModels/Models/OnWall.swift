//
//  OnWall.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 11/19/25.
//

import Foundation

struct OnWall: Sendable, Equatable {
    var route: String
    var name: String
    var score: String?
    
    func commit() {
        let documentDirectory = URL.documentsDirectory

        let resultPath = documentDirectory.appending(
            path: "\(route)Results.txt"
        )
        do {
            try name.write(
                to: resultPath,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            print(error.localizedDescription)
        }
    }
}
