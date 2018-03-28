//
//  Network.swift
//  Network
//
//  Created by Fabio Ferrero on 17/03/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation
import UIKit

enum NetworkError: Error, CustomStringConvertible {
    case invalidURL
    case missingData
    case encodingError(errorMessage: String)
    case decodingError(errorMessage: String)
    case networkError(errorMessage: String)
    
    var description: String {
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

// TODO: Service Extension
// Add an extension to the `Service` protocol so that it can return a Request
// ready with itself.
protocol Service {
    static var url: String { get }
    associatedtype Input: Encodable
    associatedtype Output: Decodable
}

final class Network: NSObject {
    
    /// The singleton for the Network class. This class can be used only by
    /// means of this `shared` instance.
    static let shared: Network = Network()
    
    enum Response<D: Decodable> {
        case OK(response: D)
        case KO(error: NetworkError)
    }
    
    struct Request<S: Service> {
        var serviceUrl: String = S.url
        var payload: S.Input
        
        init(payload: S.Input) {
            self.payload = payload
        }
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
    
    // MARK: Encoder & Decoder
    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
    private lazy var decoder: JSONDecoder = {
        return JSONDecoder()
    }()
    
    // Make the initializer private for the singleton
    private override init() { super.init() }
}

// MARK: - Calls

extension Network {
    
    func callService<S>(withNewRequest request: Request<S>, callback: @escaping (_ response: Response<S.Output>) -> Void) {
        
        guard let url = URL(string: request.serviceUrl) else {
            callback(Response.KO(error: .invalidURL)); return
        }
        
        do {
            let data = try encoder.encode(request.payload)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                let log = "⬆️ REQUEST to: \(url)\n\(jsonString)"
                print(log)
            }
            
            let httpRequest = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.timeoutInterval)
            httpRequest.httpMethod = "POST"
            httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
            httpRequest.httpBody = data // It is possible to encrypt this data here
            
            let downloadTask = backgroundSession.downloadTask(with: httpRequest as URLRequest)
            
            Network.shared.add(task: downloadTask, withRelatedCompletionHandler: { data, urlResponse, error in
                defer { self.remove(task: downloadTask) }
                
                if let error = error {
                    callback(Response.KO(error: .networkError(errorMessage: error.localizedDescription)))
                } else {
                    guard let data = data else {
                        callback(Response.KO(error: .missingData)); return
                    }
                    
                    if let jsonString = String(data: data, encoding: .utf8) {
                        let log = "⬇️ RESPONSE from: \(url)\n\(jsonString)"
                        print(log)
                    }
                    
                    do {
                        let response = try self.decoder.decode(S.Output.self, from: data)
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

// MARK: - Session Delegate

extension Network: URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    
    // This delegate method is needed in order to reactivate the backgroud
    // session when the app is not in foreground
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroudSessionCompletionHandler {
                appDelegate.backgroudSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
    
    // This delegate method is called when session task is finished. Check for
    // presence of `error` object to decide if call was successful or not
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
    
    // This delegate method is called once when response is recieved. This is
    // the place where you can perform initialization or other related tasks
    // before start recieviing data from response
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        httpResponses[dataTask]?.urlResponse = response
        completionHandler(.allow)
    }
    
    // This delegate method is called when response data is recieved in chunks
    // or in one shot.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataBuffers[dataTask]?.append(data)
    }
    
    // This delegate method id called when the `dowloadTask` has finished its
    // work of downloading. It wrote in `location` all dowloaded data.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            dataBuffers[downloadTask]?.append(data)
        } catch {
            print(error.localizedDescription)
        }
    }
}
