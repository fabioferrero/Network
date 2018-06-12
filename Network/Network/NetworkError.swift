//
//  NetworkError.swift
//  Network
//
//  Created by Fabio Ferrero on 10/06/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case missingData
    case encodingError(errorMessage: String)
    case decodingError(errorMessage: String)
    case networkError(errorMessage: String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL in request: cannot create URL from String."
        case .missingData: return "Missing data in response."
        case .encodingError(let errorMessage): return "Error during payload encoding: \(errorMessage)"
        case .decodingError(let errorMessage): return "Error during data decoding: \(errorMessage)"
        case .networkError(let errorMessage): return errorMessage
        }
    }
}
