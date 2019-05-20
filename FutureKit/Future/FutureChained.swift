//
//  FutureChained.swift
//  Network
//
//  Created by Fabio Ferrero on 27/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public extension Future {
    func chained<NextValue>(with closure: @escaping (Value) throws -> Future<NextValue>) -> Future<NextValue> {
        
        // Create a wrapper Promise that will be returned by this method
        let promise = Promise<NextValue>()
        
        // Look for changes to the current Future
        observe(on: .background) { result in
            switch result {
            case .success(let value):
                do {
                    // Try to execute the input closure in order to create a new
                    // Future given the first one
                    let future: Future<NextValue> = try closure(value)
                    
                    // Now observe the new future, in order to correctly resolve
                    // the Promise with a value or an error
                    future.observe(on: .background) { result in
                        switch result {
                        case .success(let value):
                            promise.resolve(with: value)
                        case .failure(let error):
                            promise.reject(with: error)
                        }
                    }
                } catch {
                    promise.reject(with: error)
                }
            case .failure(let error):
                promise.reject(with: error)
            }
        }
        
        return promise
    }
}

public extension Future {
    func performing(action: @escaping (Value) throws -> Void) -> Future<Value> {
        return chained { value in
            try action(value)
            return self
        }
    }
}
