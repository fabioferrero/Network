//
//  Future.swift
//  Network
//
//  Created by Fabio Ferrero on 27/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

class Future<Value> {
    fileprivate var result: Result<Value, Swift.Error>? {
        // Observe result assignment and report it
        didSet { result.map(report) }
    }
    
    private typealias Callback = (Result<Value, Swift.Error>) -> Void
    private typealias SuccessCallback = (Value) -> Void
    private typealias FailureCallback = (Swift.Error) -> Void
    
    private lazy var callbacks = [Callback]()
    private lazy var onSuccessCallbacks = [SuccessCallback]()
    private lazy var onFailureCallbacks = [FailureCallback]()
    
    func observe(with callback: @escaping (Result<Value, Swift.Error>) -> Void) {
        callbacks.append(callback)
        
        // If a result has already been set, call the callback directly
        result.map(callback)
    }
    
    @discardableResult
    func onSuccess(do callback: @escaping (Value) -> Void) -> Future<Value> {
        onSuccessCallbacks.append(callback)
        
        // If a result has already been set, call the success callback directly
        // only if the result is a success
        result.map { result in
            if case Result.success(let value) = result { callback(value) }
        }
        return self
    }
    
    @discardableResult
    func onFailure(do callback: @escaping (Swift.Error) -> Void) -> Future<Value> {
        onFailureCallbacks.append(callback)
        
        // If a result has already been set, call the failure callback directly
        // only if the result is a failure
        result.map { result in
            if case Result.failure(let error) = result { callback(error) }
        }
        return self
    }
    
    private func report(result: Result<Value, Swift.Error>) {
        for callback in callbacks {
            DispatchQueue.main.async { callback(result) }
        }
        if case Result.success(let value) = result {
            onSuccessCallbacks.forEach { callback in
                DispatchQueue.main.async { callback(value) }
            }
        }
        if case Result.failure(let error) = result {
            onFailureCallbacks.forEach { callback in
                DispatchQueue.main.async { callback(error) }
            }
        }
    }
}

class Promise<Value>: Future<Value> {
    init(value: Value? = nil) {
        super.init()
        
        // If a value is already given in input, we can report the value directly
        result = value.map { value in Result.success(value) }
    }
    
    func resolve(with value: Value) {
        result = .success(value)
    }
    
    func reject(with error: Swift.Error) {
        result = .failure(error)
    }
}
