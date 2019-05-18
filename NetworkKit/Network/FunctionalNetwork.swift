//
//  FunctionalNetwork.swift
//  NetworkKit
//
//  Created by Fabio Ferrero on 08/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation
import FutureKit

extension Network {
    public struct Endpoint {
        var url: String
        var method: HTTPMethod
        
        public init(url: String, method: HTTPMethod = .get) {
            self.url = url
            self.method = method
        }
    }
    
    public func request(_ endpoint: Endpoint) -> Future<Data> {
        return request(endpoint, with: nil as Optional<String>) // Help compiler insted of using default argument list
    }
    
    public func request<Input: Encodable>(_ endpoint: Endpoint, with input: Input?) -> Future<Data> {
        // Start by constructing a Promise, that will later be
        // returned as a Future
        let promise = Promise<Data>()
        
        guard let url = URL(string: endpoint.url) else {
            promise.reject(with: Error.invalidURL); return promise
        }
        
        do {
            let data: Data
            if let input = input { data = try encoder.encode(input) } else { data = Data() }
            
            log(input: input, for: url, with: endpoint.method)
            
            var httpRequest: URLRequest = createHTTPRequest(method: endpoint.method, for: url, with: data)
            let task: URLSessionDownloadTask = backgroundSession.downloadTask(with: httpRequest)
            
            // Perform a task, just like normal
            self.add(task: task, withRelatedCompletionHandler: { [weak self] data, urlResponse, error in
                defer { self?.remove(task: task) }
                // Reject or resolve the promise, depending on the result
                if let error = error {
                    if let httpResponse: HTTPURLResponse = urlResponse {
                        promise.reject(with: Error.httpError(httpResponse, message: error.localizedDescription))
                    } else {
                        promise.reject(with: Error.networkError(message: error.localizedDescription))
                    }
                } else {
                    if let data = data {
                        self?.log(data: data, from: url, with: urlResponse)
                        promise.resolve(with: data)
                    } else {
                        promise.reject(with: Error.missingData)
                    }
                }
            })
            
            task.resume()
        } catch {
            promise.reject(with: Error.encodingError(message: error.localizedDescription))
        }
        
        return promise
    }
}
