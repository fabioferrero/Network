//
//  Network.swift
//  Network
//
//  Created by Fabio Ferrero on 17/03/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation
import FutureKit

protocol DataService {
    associatedtype Output: Decodable
    static var path: String { get }
}

extension DataService {
    static var method: HTTPMethod { return .get }
}

protocol IOService: DataService {
    associatedtype Input: Encodable
    static var method: HTTPMethod { get }
}

final class Network: NSObject {
    
    /// The singleton for the Network class. This class can be used only by
    /// means of this `shared` instance.
    static let shared: Network = Network()
    private override init() { super.init() }
    
    var securityManager: SecurityManager?
    var encoder: DataEncoder = DataManager.default
    var decoder: DataDecoder = DataManager.default
    
    private lazy var backgroundSession: URLSession = {
        let configuration: URLSessionConfiguration = .background(withIdentifier: Constants.sessionIdentifier)
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return urlSession
    }()
    
    private typealias HTTPResponse = (data: Data?, urlResponse: HTTPURLResponse?, error: Swift.Error?)
    private typealias CompletionHandler = (_ data: Data?, _ urlResponse: HTTPURLResponse?, _ error: Swift.Error?) -> Void
    
    // MARK: HTTP Response
    private var httpResponses: [URLSessionTask: HTTPResponse] = [:]
    private var dataBuffers: [URLSessionTask: Data] = [:]
    private var completionHandlers: [URLSessionTask: CompletionHandler] = [:]
    
    var backgroudSessionCompletionHandler: (() -> Void)?
    
    // MARK: Network call
    
    enum Queue { case main; case background }
    
    func call<S: IOService, Input, Output>(service: S.Type, input: Input, onQueue responseQueue: Queue = .main, onCompletion: @escaping (_ response: Result<Output, Swift.Error>) -> Void) where Input == S.Input, Output == S.Output {
        
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
                #warning("TODO: Create Network logger")
                print("⬆️ Request to: \(url)\n\(inputDescription)")
            }
            
            var httpRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.timeoutInterval)
            httpRequest.httpMethod = String(describing: S.method)
            httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
            httpRequest.httpBody = securityManager?.encrypt(data: data) ?? data
            
            let downloadTask: URLSessionDownloadTask = backgroundSession.downloadTask(with: httpRequest)
            
            Network.shared.add(task: downloadTask, withRelatedCompletionHandler: { [weak self] data, urlResponse, error in
                defer { self?.remove(task: downloadTask) }
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
                        #warning("TODO: Create Network logger")
                        print("⬇️ Response from: \(url)\n\(outputDescription)")
                    }
                    
                    do {
                        let response: Output = try self.decoder.decode(S.Output.self, from: data)
                        completion(Result.success(response))
                    } catch {
                        completion(Result.failure(Error.decodingError(message: error.localizedDescription)))
                    }
                }
            })
            
            downloadTask.resume()
        } catch {
            completion(Result.failure(Error.encodingError(message: error.localizedDescription)))
        }
    }
    
    func request<Service: IOService>(service: Service.Type, input: Service.Input) -> Future<Data> {
        
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
    
    func request<Service: DataService>(service: Service.Type) -> Future<Data> {
        
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
}

extension Network {
    enum Error: Swift.Error {
        case invalidURL
        case missingData
        case encodingError(message: String)
        case decodingError(message: String)
        case networkError(message: String)
        case httpError(_ urlResponse: HTTPURLResponse, message: String)
        
        var localizedDescription: String {
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

private extension Network {
    #warning("TODO: Create a configuration instead of Constants")
    struct Constants {
        static let sessionIdentifier: String = "Network.BackgroundSessionIdentifier"
        static let timeoutInterval: TimeInterval = 10.0
    }
}

// MARK: - Session Delegates

extension Network: URLSessionDelegate {
    // This delegate method is needed in order to reactivate the backgroud
    // session when the app is not in foreground
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let completionHandler = self.backgroudSessionCompletionHandler {
            self.backgroudSessionCompletionHandler = nil
            completionHandler()
        }
    }
}

extension Network: URLSessionDataDelegate {
    // This delegate method is called when session task is finished. Check for
    // presence of `error` object to decide if call was successful or not
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Swift.Error?) {
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
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        httpResponses[dataTask]?.urlResponse = response as? HTTPURLResponse
        completionHandler(.allow)
    }
    
    // This delegate method is called when response data is recieved in chunks
    // or in one shot.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataBuffers[dataTask]?.append(data)
    }
}

extension Network: URLSessionDownloadDelegate {
    // This delegate method id called when the `dowloadTask` has finished its
    // work of downloading. It wrote in `location` all dowloaded data.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let data = try Data(contentsOf: location)
            dataBuffers[downloadTask]?.append(data)
        } catch {
            #warning("TODO: Create Network logger")
            print("Error: " + error.localizedDescription)
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
