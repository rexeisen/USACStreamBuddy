//
//  OnWall.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 11/19/25.
//

import Foundation

struct OnWall: Sendable, Equatable, CustomDebugStringConvertible {
    var route: String
    var bib: String
    var name: String
    var score: String?
    
    var debugDescription: String {
        "#\(bib) \(name)"
    }
    
    func commit() {
        let documentDirectory = URL.documentsDirectory

        let resultPath = documentDirectory.appending(
            path: "\(route)Results.txt"
        )
        let value = "#\(bib) \(name)"
        do {
            try value.write(
                to: resultPath,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            print(error.localizedDescription)
        }
        
        writeImages()
    }
    
    private func writeImages() {
        let documentDirectory = URL.documentsDirectory
        if let score {
            let sourcePath = documentDirectory.appending(path: "rawScoreResults/\(score).png" )
            let destinationPath = documentDirectory.appending(path: "\(route)Score.png" )
            
            _ = try? FileManager.default.removeItem(at: destinationPath)
            do {
                _ = try FileManager.default.copyItem(at: sourcePath, to: destinationPath)
                _ = try FileManager.default.setAttributes([.modificationDate : Date()], ofItemAtPath: destinationPath.path)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // Lets copy the competitor now
        let sourceCompetitorPath = documentDirectory.appending(path: "square/\(bib).jpg" )
        let blankCompetitorPath = documentDirectory.appending(path: "blankCompetitor.jpg" )
        let destinationCompetitorPath = documentDirectory.appending(path: "Competitor-\(route).jpg" )
        
        _ = try? FileManager.default.removeItem(at: destinationCompetitorPath)
        do {
            if FileManager.default.fileExists(atPath: sourceCompetitorPath.path) {
                _ = try FileManager.default.copyItem(at: sourceCompetitorPath, to: destinationCompetitorPath)
            } else {
                _ = try FileManager.default.copyItem(at: blankCompetitorPath, to: destinationCompetitorPath)
            }
            _ = try FileManager.default.setAttributes([.modificationDate : Date()], ofItemAtPath: destinationCompetitorPath.path)
        } catch {
            print(error.localizedDescription)
        }
    }
}
