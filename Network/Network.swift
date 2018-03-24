//
//  Network.swift
//  Network
//
//  Created by Fabio Ferrero on 17/03/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation
import UIKit

enum NetworkError: Error {
    case invalidURL
    case missingData
    case encodingError(errorMessage: String)
    case decodingError(errorMessage: String)
    case networkError(errorMessage: String)
    
    var message: String {
        switch self {
        case .invalidURL: return "Invalid URL in request: cannot create URL from String."
        case .missingData: return "Missing data in response."
        case .encodingError(let errorMessage): return "Error during payload encoding: \(errorMessage)"
        case .decodingError(let errorMessage): return "Error during data decoding: \(errorMessage)"
        case .networkError(let errorMessage): return errorMessage
        }
    }
}

// MARK: - Data Structures

extension Network {
    
    struct Constants {
        static let sessionIdentifier = "Network.BackgroundSessionIdentifier"
        static let timeoutInterval: TimeInterval = 20
    }
}

final class Network: NSObject {
    
    static let shared: Network = Network()
    
    enum Response<D: Decodable> {
        case OK(response: D)
        case KO(error: NetworkError)
    }
    
    struct Request<E: Encodable> {
        var serviceUrl: String
        var payload: E
    }
    
    // MARK: Sessions
    private lazy var backgroundSession: URLSession = {
        let configuration: URLSessionConfiguration = .background(withIdentifier: Constants.sessionIdentifier)
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    private typealias HTTPResponse = (data: Data?, urlResponse: URLResponse?, error: Error?)
    private typealias CompletionHandler = (_ data: Data?, _ urlResponse: URLResponse?, _ error: Error?) -> Void
    
    // MARK: HTTP Response
    private var httpResponses: [URLSessionTask: HTTPResponse] = [:]
    private var dataBuffers: [URLSessionTask: Data] = [:]
    private var completionHandlers: [URLSessionTask: CompletionHandler] = [:]
    
    // Make the initializer private for the singleton
    private override init() { super.init() }
}

// MARK: - Session Delegate

extension Network: URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroudSessionCompletionHandler {
                appDelegate.backgroudSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
    
    /// This delegate method is called when session task is finished. Check for
    /// presence of `error` object to decide if call was successful or not
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            httpResponses[task]?.error = error
        } else if let data = dataBuffers[task] {
            if data.count > 0 {
                httpResponses[task]?.data = data
            }
            dataBuffers[task] = nil // Clean the buffer
        }
        DispatchQueue.main.async {
            if let httpResponse = self.httpResponses[task] {
                self.completionHandlers[task]?(httpResponse.data, httpResponse.urlResponse, httpResponse.error)
            }
        }
    }
    
    /// This delegate method is called once when response is recieved. This is
    /// the place where you can perform initialization or other related tasks
    /// before start recieviing data from response
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        httpResponses[dataTask]?.urlResponse = response
        completionHandler(.allow)
    }
    
    /// This delegate method is called when response data is recieved in chunks
    /// or in one shot.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataBuffers[dataTask]?.append(data)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        do {
            let data = try Data(contentsOf: location)
            dataBuffers[downloadTask]?.append(data)
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - Privates

extension Network {
    
    private func add(task: URLSessionTask, withRelatedCompletionHandler completion: @escaping CompletionHandler) {
        httpResponses[task] = (nil, nil, nil)
        dataBuffers[task] = Data()
        completionHandlers[task] = completion
    }
    
    private func remove(task: URLSessionTask) {
        httpResponses[task] = nil
        dataBuffers[task] = nil
        completionHandlers[task] = nil
    }
}

// MARK: - Calls

extension Network {
    
    func callService<E, D>(withRequest request: Request<E>, callback: @escaping (_ response: Response<D>) -> Void) {
        
        guard let url = URL(string: request.serviceUrl) else {
            callback(Response.KO(error: .invalidURL)); return
        }
        
        do {
            let data = try JSONEncoder().encode(request.payload)
            
            let httpRequest = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.timeoutInterval)
            httpRequest.httpMethod = "POST"
            httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
            httpRequest.httpBody = data // It is possible to encrypt this data here
            
            let downloadTask = backgroundSession.downloadTask(with: httpRequest as URLRequest)
            
            add(task: downloadTask, withRelatedCompletionHandler: { data, urlResponse, error in
                defer { self.remove(task: downloadTask) }
                
                if let error = error {
                    callback(Response.KO(error: .networkError(errorMessage: error.localizedDescription)))
                } else {
                    guard let data = data else {
                        callback(Response.KO(error: .missingData)); return
                    }
                    
                    do {
                        let response = try JSONDecoder().decode(D.self, from: data)
                        callback(Response.OK(response: response))
                    } catch {
                        callback(Response.KO(error: .decodingError(errorMessage: error.localizedDescription)))
                    }
                }
            })
            
            downloadTask.resume()
        } catch {
            callback(Response.KO(error: .encodingError(errorMessage: error.localizedDescription)))
        }
    }
    
    func callService<Decodable>(withURL url: URL, callback: @escaping (_ response: Response<Decodable>) -> Void) {
        
        let dataTask = backgroundSession.dataTask(with: url)
        
        add(task: dataTask, withRelatedCompletionHandler: { data, urlResponse, error in
            defer { self.remove(task: dataTask) }
            
            if let error = error {
                callback(Response.KO(error: .networkError(errorMessage: error.localizedDescription)))
            } else {
                guard let data = data else { return }
                
                do {
                    let response = try JSONDecoder().decode(Decodable.self, from: data)
                    callback(Response.OK(response: response))
                } catch {
                    callback(Response.KO(error: .decodingError(errorMessage: error.localizedDescription)))
                }
            }
        })
        
        dataTask.resume()
    }
}
