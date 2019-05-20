//
//  Error.swift
//  NetworkKit
//
//  Created by Fabio Ferrero on 20/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

extension Network {
    enum Error: Swift.Error, LocalizedError {
        case invalidURL
        case missingData
        case encodingError(message: String)
        case decodingError(message: String)
        case networkError(message: String)
        case httpError(_ urlResponse: HTTPURLResponse, message: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL in request: cannot create URL from String."
            case .missingData: return "Missing data in response."
            case .encodingError(let errorMessage): return "Error during payload encoding: \(errorMessage)"
            case .decodingError(let errorMessage): return "Error during data decoding: \(errorMessage)"
            case .networkError(let errorMessage): return errorMessage
            case let .httpError(response, errorMessage): return "[\(response.statusCode)] " + errorMessage
            }
        }
    }
}
