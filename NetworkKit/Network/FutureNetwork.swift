//
//  FutureNetwork.swift
//  Network
//
//  Created by Fabio Ferrero on 03/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation
import FutureKit

extension Network {
    public func request<Service: DataService>(service: Service.Type) -> Future<Data> {
        return request(to: service.path, method: service.method, input: nil as String?)
    }
    
    public func request<Service: IOService>(service: Service.Type, input: Service.Input) -> Future<Data> {
        return request(to: service.path, method: service.method, input: input)
    }
    
    func request<Input: Encodable>(to url: String, method: HTTPMethod, input: Input?) -> Future<Data> {
        
        let promise = Promise<Data>()
        
        guard let url = URL(string: url) else {
            promise.reject(with: Error.invalidURL); return promise
        }
        
        do {
            let data: Data
            if let input = input { data = try encoder.encode(input) } else { data = Data() }
            
            log(input: input, for: url, with: method)
            
            var httpRequest: URLRequest = createHTTPRequest(method: method, for: url, with: data)
            let task: URLSessionDownloadTask = backgroundSession.downloadTask(with: httpRequest)
            
            self.add(task: task, withRelatedCompletionHandler: { [weak self] data, urlResponse, error in
                defer { self?.remove(task: task) }
                
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

extension Network {
    private func log<Input: Encodable>(input: Input?, for url: URL, with method: HTTPMethod) {
        let httpMethod: String = String(describing: method)
        print("⬆️\t[N] \(httpMethod) Request to \(url)")
        if let input = input, let inputDescription: String = encoder.string(for: input) {
            print(inputDescription)
        }
    }
    
    private func log(data: Data, from url: URL, with urlResponse: URLResponse?) {
        if let code: Int = (urlResponse as? HTTPURLResponse)?.statusCode,
            let httpCode = HTTPStatusCode(rawValue: code) {
            print("⬇️\t[N] Response from \(url) -> \(httpCode)", terminator: "")
        } else {
            print("⬇️\t[N] Response from \(url)", terminator: "")
        }
        if let outputDescription = self.decoder.string(from: data) {
            print("\n\(outputDescription)")
        } else {
            print(" [\(data)]")
        }
    }
}
