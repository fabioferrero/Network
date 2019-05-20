//
//  Logger.swift
//  NetworkKit
//
//  Created by Fabio Ferrero on 20/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

struct Logger {
    
    private static var decoder: DataDecoder = DataManager.default
    private static var encoder: DataEncoder = DataManager.default
    
    private static var isNetworkLogEnabled: Bool {
        return ProcessInfo.processInfo.environment["LOG_NETWORK"] == "enable"
    }
    
    static func log<Input: Encodable>(input: Input?, for url: URL, with method: HTTPMethod) {
        #if DEBUG
        if isNetworkLogEnabled {
            let httpMethod: String = String(describing: method)
            print("⬆️\t[N] \(httpMethod) Request to \(url)")
            if let input = input, let inputDescription: String = encoder.string(for: input) {
                print(inputDescription)
            }
        }
        #endif
    }
    
    static func log(data: Data, from url: URL, with urlResponse: URLResponse?) {
        #if DEBUG
        if isNetworkLogEnabled {
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
        #endif
    }
    
    static func log(error: Error) {
        #if DEBUG
        if isNetworkLogEnabled {
            print("❌\t[E] Error: " + error.localizedDescription)
        }
        #endif
    }
}
