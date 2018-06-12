//
//  Network.swift
//  Network
//
//  Created by Fabio Ferrero on 17/03/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation
import UIKit

final class Network: NSObject, Repository {
    
    /// The singleton for the Network class. This class can be used only by
    /// means of this `shared` instance.
    static let shared: Network = Network()
    private override init() { super.init() }
    
    // MARK: Session
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
    
    func perform<S>(_ request: Request<S>, onCompletion: @escaping (_ response: Response<S.Output>) -> Void) where S: Service {
        
        guard let url = URL(string: S.url) else {
            onCompletion(Response.KO(error: NetworkError.invalidURL)); return
        }
        
        do {
            let data = try encoder.encode(request.payload)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                Logger.log(.info, message: "⬆️ Request to: \(url)\n\(jsonString)")
            }
            
            let httpRequest = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.timeoutInterval)
            httpRequest.httpMethod = "POST"
            httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
            httpRequest.httpBody = data // It is possible to encrypt this data here
            
            let downloadTask = backgroundSession.downloadTask(with: httpRequest as URLRequest)
            
            Network.shared.add(task: downloadTask, withRelatedCompletionHandler: { data, urlResponse, error in
                defer { self.remove(task: downloadTask) }
                
                if let error = error {
                    onCompletion(Response.KO(error: NetworkError.networkError(errorMessage: error.localizedDescription)))
                } else {
                    guard let data = data else {
                        onCompletion(Response.KO(error: NetworkError.missingData)); return
                    }
                    
                    if let jsonString = String(data: data, encoding: .utf8) {
                        Logger.log(.info, message: "⬇️ Response from: \(url)\n\(jsonString)")
                    }
                    
                    do {
                        let response = try self.decoder.decode(S.Output.self, from: data)
                        onCompletion(Response.OK(response: response))
                    } catch {
                        onCompletion(Response.KO(error: NetworkError.decodingError(errorMessage: error.localizedDescription)))
                    }
                }
            })
            
            downloadTask.resume()
        } catch {
            onCompletion(Response.KO(error: NetworkError.encodingError(errorMessage: error.localizedDescription)))
        }
    }
}

// MARK - Constants

extension Network {
    
    struct Constants {
        static let sessionIdentifier = "Network.BackgroundSessionIdentifier"
        static let timeoutInterval: TimeInterval = 20
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
            Logger.log(.error, message: error.localizedDescription)
        }
    }
}
