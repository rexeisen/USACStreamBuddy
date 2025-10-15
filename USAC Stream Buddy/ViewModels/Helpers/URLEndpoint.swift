//
//  URLBuilder.swift
//  USAC Stream Buddy
//
//  Created by Jon Rexeisen on 10/14/25.
//

import Foundation

enum URLEndpoint {
    enum EndpointError: Error {
        case malformedURL
    }
    
    case schedule
    case event(Int)
    case results(Int, Int)
    
    func url() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "usac.results.info"
        switch self {
        case .schedule:
            components.path = "/api/v1/seasons/5"
        case .event(let eventId):
            components.path = "/api/v1/events/\(eventId)"
        case .results(let eventId, let categoryId):
            components.path = "/api/v1/events/\(eventId)/result/\(categoryId)"
        }
        
        guard let endpoint = components.url else { throw EndpointError.malformedURL }
        var request = URLRequest(url: endpoint)
        request.setValue("https://usac.results.info/", forHTTPHeaderField: "Referer")
        return request
    }
}
