//
//  URLSession.swift
//  Network
//
//  Created by Fabio Ferrero on 01/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation
import FutureKit

extension URLSession {
    func request<Service: DataService>(for service: Service) -> Future<Data> {
        // Start by constructing a Promise, that will later be
        // returned as a Future
        let promise = Promise<Data>()
        
        guard let url: URL = URL(string: Service.path) else {
            promise.reject(with: Error.invalidURL); return promise
        }
        
        // Perform a data task, just like normal
        let task = dataTask(with: url) { data, _, error in
            // Reject or resolve the promise, depending on the result
            if let error = error {
                promise.reject(with: error)
            } else {
                if let data = data {
                    promise.resolve(with: data)
                } else {
                    promise.reject(with: Error.missingData)
                }
            }
        }
        
        task.resume()
        
        return promise
    }
}

extension URLSession {
    enum Error: Swift.Error, LocalizedError {
        case missingData
        case invalidURL
        
        var errorDescription: String? {
            switch self {
            case .missingData: return "Missing data in response."
            case .invalidURL: return "Invalid URL in request: cannot create URL from String."
            }
        }
    }
}
