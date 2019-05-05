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
        
        let promise = Promise<Data>()
        
        guard let url = URL(string: service.path) else {
            promise.reject(with: Error.invalidURL); return promise
        }
        
        let httpMethod: String = String(describing: service.method)
        #warning("TODO: Create Network logger")
        print("⬆️ \(httpMethod) Request to: \(url)")
        
        var httpRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.timeoutInterval)
        httpRequest.httpMethod = httpMethod
        httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
        httpRequest.httpBody = nil
        
        let downloadTask: URLSessionDownloadTask = backgroundSession.downloadTask(with: httpRequest)
        
        Network.shared.add(task: downloadTask, withRelatedCompletionHandler: { [weak self] data, urlResponse, error in
            defer { self?.remove(task: downloadTask) }
            
            if let error = error {
                if let httpResponse: HTTPURLResponse = urlResponse {
                    promise.reject(with: Error.httpError(httpResponse, message: error.localizedDescription))
                } else {
                    promise.reject(with: Error.networkError(message: error.localizedDescription))
                }
            } else {
                if let data = data {
                    promise.resolve(with: data)
                } else {
                    promise.reject(with: Error.missingData)
                }
            }
        })
        
        downloadTask.resume()
        
        return promise
    }
    
    public func request<Service: IOService>(service: Service.Type, input: Service.Input) -> Future<Data> {
        
        let promise = Promise<Data>()
        
        guard let url = URL(string: service.path) else {
            promise.reject(with: Error.invalidURL); return promise
        }
        
        do {
            let data: Data = try encoder.encode(input)
            
            let httpMethod: String = String(describing: service.method)
            if let inputDescription: String = encoder.string(for: input) {
                #warning("TODO: Create Network logger")
                print("⬆️ \(httpMethod) Request to: \(url)\n\(inputDescription)")
            }
            
            var httpRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.timeoutInterval)
            httpRequest.httpMethod = httpMethod
            httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
            httpRequest.httpBody = securityManager?.encrypt(data: data) ?? data
            
            let downloadTask: URLSessionDownloadTask = backgroundSession.downloadTask(with: httpRequest)
            
            Network.shared.add(task: downloadTask, withRelatedCompletionHandler: { [weak self] data, urlResponse, error in
                defer { self?.remove(task: downloadTask) }
                
                if let error = error {
                    if let httpResponse: HTTPURLResponse = urlResponse {
                        promise.reject(with: Error.httpError(httpResponse, message: error.localizedDescription))
                    } else {
                        promise.reject(with: Error.networkError(message: error.localizedDescription))
                    }
                } else {
                    if let data = data {
                        promise.resolve(with: data)
                    } else {
                        promise.reject(with: Error.missingData)
                    }
                }
            })
            
            downloadTask.resume()
        } catch {
            promise.reject(with: Error.encodingError(message: error.localizedDescription))
        }
        
        return promise
    }
}
