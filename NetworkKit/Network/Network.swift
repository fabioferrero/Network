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
    public var decoder: DataDecoder = DataManager.default
    public var encoder: DataEncoder = DataManager.default
    
    private var configuration: Configuration
    
    lazy var backgroundSession: URLSession = {
        let sessionConfiguration: URLSessionConfiguration = .background(withIdentifier: configuration.sessionIdentifier)
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
    
    // MARK: Network call
    
    public enum Queue { case main; case background }
    
    public func call<S: IOService, Input, Output>(service: S.Type, input: Input, onQueue responseQueue: Queue = .main, onCompletion: @escaping (_ response: Result<Output, Swift.Error>) -> Void) where Input == S.Input, Output == S.Output {
        
        func completion(_ response: Result<Output, Swift.Error>) {
            if responseQueue == Queue.main { DispatchQueue.main.async { onCompletion(response) } }
            else { onCompletion(response) }
        }
        
        guard let url = URL(string: S.path) else {
            completion(Result.failure(Error.invalidURL)); return
        }
        
        do {
            let data: Data = try encoder.encode(input)
            
            if let inputDescription: String = encoder.string(for: input) {
                print("⬆️\t[N] Request to: \(url)\n\(inputDescription)")
            }
            
            var httpRequest: URLRequest = createHTTPRequest(method: S.method, for: url, with: data)
            
            let task: URLSessionDownloadTask = backgroundSession.downloadTask(with: httpRequest)
            
            self.add(task: task, withRelatedCompletionHandler: { [weak self] data, urlResponse, error in
                defer { self?.remove(task: task) }
                guard let self = self else { return }
                
                if let error = error {
                    if let httpResponse: HTTPURLResponse = urlResponse {
                        completion(Result.failure(Error.httpError(httpResponse, message: error.localizedDescription)))
                    } else {
                        completion(Result.failure(Error.networkError(message: error.localizedDescription)))
                    }
                } else {
                    guard var data: Data = data else { completion(Result.failure(Error.missingData)); return }
                    
                    if let securityManager: SecurityManager = self.securityManager {
                        data = securityManager.decrypt(data: data)
                    }
                    
                    if let outputDescription = String(data: data, encoding: .utf8) {
                        print("⬇️\t[N] Response from: \(url)\n\(outputDescription)")
                    }
                    
                    do {
                        let response: Output = try self.decoder.decode(S.Output.self, from: data)
                        completion(Result.success(response))
                    } catch {
                        completion(Result.failure(Error.decodingError(message: error.localizedDescription)))
                    }
                }
            })
            
            task.resume()
        } catch {
            completion(Result.failure(Error.encodingError(message: error.localizedDescription)))
        }
    }
}

extension Network {
    func createHTTPRequest(method: HTTPMethod = .get, for url: URL, with data: Data = Data()) -> URLRequest {
        var httpRequest = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: configuration.timeoutInterval)
        httpRequest.httpMethod = String(describing: method)
        httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
        httpRequest.httpBody = securityManager?.encrypt(data: data) ?? data
        return httpRequest
    }
}

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
        let timeoutInterval: TimeInterval
        
        public static let `default` = Configuration(
            sessionIdentifier: "Network.BackgroundSessionIdentifier",
            timeoutInterval: 10.0
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
            print("❌\t[E] Error: " + error.localizedDescription)
        }
    }
}

/// The standard `DataEncoder` and `DataDecoder` for the Network singleton
fileprivate struct DataManager: DataEncoder, DataDecoder {
    
    static var `default`: DataManager = DataManager()
    
    private var encoder: JSONEncoder
    private var decoder: JSONDecoder
    
    private init() {
        let encoder = JSONEncoder()
        #if DEBUG
        encoder.outputFormatting = JSONEncoder.OutputFormatting.prettyPrinted
        #endif
        
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }
    
    func encode<Input: Encodable>(_ value: Input) throws -> Data {
        return try encoder.encode(value)
    }
    
    func decode<Output: Decodable>(_ type: Output.Type, from data: Data) throws -> Output {
        return try decoder.decode(type, from: data)
    }
}
