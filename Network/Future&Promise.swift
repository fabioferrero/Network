//
//  Future&Promise.swift
//  Network
//
//  Created by Fabio Ferrero on 27/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

class Future<Value> {
    fileprivate var result: Result<Value, Error>? {
        // Observe result assigning and report it
        didSet { result.map(report) }
    }
    
    private lazy var callbacks = [(Result<Value, Error>) -> Void]()
    
    func observe(with callback: @escaping (Result<Value, Error>) -> Void) {
        callbacks.append(callback)
        
        // If a result has already been set, call the callback directly
        result.map(callback)
    }
    
    private func report(result: Result<Value, Error>) {
        for callback in callbacks {
            callback(result)
        }
    }
}

class Promise<Value>: Future<Value> {
    init(value: Value? = nil) {
        super.init()
        
        // If a value is already given in input, we can report the value directly
        result = value.map(Result.success)
    }
    
    func resolve(with value: Value) {
        result = .success(value)
    }
    
    func reject(with error: Error) {
        result = .failure(error)
    }
}

extension Future {
    func chained<NextValue>(with closure: @escaping (Value) throws -> Future<NextValue>) -> Future<NextValue> {
        
        // Create a wrapper Promise that will be returned by this method
        let promise = Promise<NextValue>()
        
        // Look for changes to the current Future
        observe { result in
            switch result {
            case .success(let value):
                do {
                    // Try to execute the input closure in order to create a new
                    // Future given the first one
                    let future: Future<NextValue> = try closure(value)
                    
                    // Now observe the new future, in order to correctly resolve
                    // the Promise with a value or an error
                    future.observe { result in
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

extension Future {
    func transformed<NewValue>(with closure: @escaping (Value) throws -> NewValue) -> Future<NewValue> {
        return chained { value in
            return try Promise(value: closure(value))
        }
    }
}

extension Future where Value == Data {
    func decoded<NewValue: Decodable>() -> Future<NewValue> {
        return transformed { value in
            return try JSONDecoder().decode(NewValue.self, from: value)
        }
    }
}

//// Savable example
//
//protocol Savable {}
//
//protocol Database {
//    func save<S: Savable>(_ savable: S, callback: @escaping (Result<S, Error>) -> Void)
//}
//
//extension Future where Value: Savable {
//    func saved(in database: Database) -> Future<Value> {
//        return chained { value in
//            let promise = Promise<Value>()
//
//            database.save(value) { result in
//                switch result {
//                case .success(let value):
//                    promise.resolve(with: value)
//                case .failure(let error):
//                    promise.reject(with: error)
//                }
//            }
//
//            return promise
//        }
//    }
//}
