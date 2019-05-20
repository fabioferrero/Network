//
//  Network.swift
//  Network
//
//  Created by Fabio Ferrero on 17/03/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

public final class Network: NSObject {
    
    /// The singleton for the Network class. This class can be used only by
    /// means of this `shared` instance.
    public static let `default`: Network = Network()
    public init(with configuration: Configuration = .default) { self.configuration = configuration; super.init() }
    
    public var securityManager: SecurityManager?
    
    public var encoder: DataEncoder = DataManager.default
    
    private var configuration: Configuration
    
    lazy var backgroundSession: URLSession = {
        let sessionConfiguration: URLSessionConfiguration = .background(withIdentifier: configuration.sessionIdentifier)
        sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest
        sessionConfiguration.timeoutIntervalForResource = configuration.timeoutIntervalForResource
        let urlSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)

        return urlSession
    }()
    
    typealias HTTPResponse = (data: Data?, urlResponse: HTTPURLResponse?, error: Swift.Error?)
    typealias CompletionHandler = (_ data: Data?, _ urlResponse: HTTPURLResponse?, _ error: Swift.Error?) -> Void
    
    // MARK: HTTP Response
    private var httpResponses: [URLSessionTask: HTTPResponse] = [:]
    private var dataBuffers: [URLSessionTask: Data] = [:]
    private var completionHandlers: [URLSessionTask: CompletionHandler] = [:]
    
    public var backgroudSessionCompletionHandler: (() -> Void)?
    
    public enum Queue { case main; case background }
}

extension Network {
    func createHTTPRequest(method: HTTPMethod = .get, for url: URL, with data: Data = Data()) -> URLRequest {
        var httpRequest = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: configuration.timeoutIntervalForRequest)
        httpRequest.httpMethod = String(describing: method)
        httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
        httpRequest.httpBody = securityManager?.encrypt(data: data) ?? data
        return httpRequest
    }
}

extension Network {
    func add(task: URLSessionTask, withRelatedCompletionHandler completion: @escaping CompletionHandler) {
        httpResponses[task] = (nil, nil, nil)
        dataBuffers[task] = Data()
        completionHandlers[task] = completion
    }
    
    func remove(task: URLSessionTask) {
        httpResponses[task] = nil
        dataBuffers[task] = nil
        completionHandlers[task] = nil
    }
}

extension Network {
    public struct Configuration {
        let sessionIdentifier: String
        let timeoutIntervalForRequest: TimeInterval
        let timeoutIntervalForResource: TimeInterval
        
        public static let `default` = Configuration(
            sessionIdentifier: "Network.BackgroundSessionIdentifier",
            timeoutIntervalForRequest: 5.0,
            timeoutIntervalForResource: 20.0
        )
    }
}

// MARK: - Session Delegates

extension Network: URLSessionDelegate {
    // This delegate method is needed in order to reactivate the backgroud
    // session when the app is not in foreground
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let completionHandler = self.backgroudSessionCompletionHandler {
            self.backgroudSessionCompletionHandler = nil
            completionHandler()
        }
    }
}

extension Network: URLSessionDataDelegate {
    // This delegate method is called when session task is finished. Check for
    // presence of `error` object to decide if call was successful or not
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Swift.Error?) {
        if let error = error {
            httpResponses[task]?.error = error
        } else if let data = dataBuffers[task] {
            if data.count > 0 {
                httpResponses[task]?.data = data
            }
            dataBuffers[task] = nil // Clean the buffer
        }
        if let httpResponse = self.httpResponses[task] {
            let urlResponse: HTTPURLResponse? = (httpResponse.urlResponse ?? task.response) as? HTTPURLResponse
            self.completionHandlers[task]?(httpResponse.data, urlResponse, httpResponse.error)
        }
    }
    
    // This delegate method is called once when response is recieved. This is
    // the place where you can perform initialization or other related tasks
    // before start recieviing data from response
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        httpResponses[dataTask]?.urlResponse = response as? HTTPURLResponse
        completionHandler(.allow)
    }
    
    // This delegate method is called when response data is recieved in chunks
    // or in one shot.
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataBuffers[dataTask]?.append(data)
    }
}

extension Network: URLSessionDownloadDelegate {
    // This delegate method id called when the `dowloadTask` has finished its
    // work of downloading. It wrote in `location` all dowloaded data.
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            dataBuffers[downloadTask]?.append(data)
        } catch {
            Logger.log(error: error)
        }
    }
}
