//
//  Network.swift
//  Network
//
//  Created by Fabio Ferrero on 17/03/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import UIKit

protocol Service {
    associatedtype Input: Encodable
    associatedtype Output: Decodable
    
    static var method: HTTPMethod { get }
    static var url: String { get }
}

enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    case patch
}

extension HTTPMethod: CustomStringConvertible {
    var description: String {
        return self.rawValue.uppercased()
    }
}

protocol SecurityManager {
    func encrypt(data: Data) -> Data
    func decrypt(data: Data) -> Data
}

protocol DataEncoder {
    func encode<Input: Encodable>(_ value: Input) throws -> Data
    func string<Input: Encodable>(for value: Input) -> String?
}

extension DataEncoder {
    func string<Input>(for value: Input) -> String? where Input : Encodable {
        guard let data: Data = try? self.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

protocol DataDecoder {
    func decode<Output: Decodable>(_ type: Output.Type, from data: Data) throws -> Output
}

fileprivate struct DataManager: DataEncoder, DataDecoder {
    
    static var `default`: DataManager = DataManager()
    
    private var encoder: JSONEncoder
    private var decoder: JSONDecoder
    
    private init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = JSONEncoder.OutputFormatting.prettyPrinted
        
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

final class Network: NSObject, Repository {
    
    /// The singleton for the Network class. This class can be used only by
    /// means of this `shared` instance.
    static let shared: Network = Network()
    private override init() {
        self.encoder = DataManager.default
        self.decoder = DataManager.default
        super.init()
    }
    
    var securityManager: SecurityManager?
    var encoder: DataEncoder
    var decoder: DataDecoder
    
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
    
    func callService<S: Service, Input, Output>(_ service: S, input: Input, onCompletion: @escaping (_ response: Result<Output, Error>) -> Void) where Input == S.Input, Output == S.Output {
        
        guard let url = URL(string: S.url) else {
            onCompletion(Result.failure(NetworkError.invalidURL)); return
        }
        
        do {
            let data = try encoder.encode(input)
            
            if let inputDescription = encoder.string(for: input) {
                Logger.log(.info, message: "⬆️ Request to: \(url)\n\(inputDescription)")
            }
            
            var httpRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.timeoutInterval)
            httpRequest.httpMethod = String(describing: S.method)
            httpRequest.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-type")
            httpRequest.httpBody = securityManager?.encrypt(data: data) ?? data
            
            let downloadTask = backgroundSession.downloadTask(with: httpRequest)
            
            Network.shared.add(task: downloadTask, withRelatedCompletionHandler: { [weak self] data, urlResponse, error in
                defer { self?.remove(task: downloadTask) }
                guard let self = self else { return }
                
                if let error = error {
                    onCompletion(Result.failure(NetworkError.networkError(message: error.localizedDescription)))
                } else {
                    guard var data = data else { onCompletion(Result.failure(NetworkError.missingData)); return }
                    
                    if let securityManager = self.securityManager {
                        data = securityManager.decrypt(data: data)
                    }
                    
                    if let outputDescription = String(data: data, encoding: .utf8) {
                        Logger.log(.info, message: "⬇️ Response from: \(url)\n\(outputDescription)")
                    }
                    
                    do {
                        let response: Output = try self.decoder.decode(S.Output.self, from: data)
                        onCompletion(Result.success(response))
                    } catch {
                        onCompletion(Result.failure(NetworkError.decodingError(message: error.localizedDescription)))
                    }
                }
            })
            
            downloadTask.resume()
        } catch {
            onCompletion(Result.failure(NetworkError.encodingError(message: error.localizedDescription)))
        }
    }
}

// MARK - Constants

extension Network {
    
    struct Constants {
        static let sessionIdentifier: String = "Network.BackgroundSessionIdentifier"
        static let timeoutInterval: TimeInterval = 20.0
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
