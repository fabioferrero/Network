//
//  Future.swift
//  Network
//
//  Created by Fabio Ferrero on 27/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public class Future<Value> {
    fileprivate var result: Result<Value, Swift.Error>? {
        // Observe result assignment and report it
        didSet { result.map(report) }
    }
    
    private typealias Callback = (Result<Value, Swift.Error>) -> Void
    private typealias SuccessCallback = (Value) -> Void
    private typealias FailureCallback = (Swift.Error) -> Void
    
    private lazy var callbacks = [(Queue, Callback)]()
    private lazy var onSuccessCallbacks = [(Queue, SuccessCallback)]()
    private lazy var onFailureCallbacks = [(Queue, FailureCallback)]()
    
    public enum Queue { case main; case background }
    
    public func observe(on queue: Queue = .main, with callback: @escaping (Result<Value, Swift.Error>) -> Void) {
        callbacks.append((queue, callback))
        
        // If a result has already been set, call the callback directly
        result.map { result in
            switch queue {
            case .main: DispatchQueue.main.async { callback(result) }
            case .background: callback(result)
            }
        }
    }
    
    @discardableResult
    public func onSuccess(on queue: Queue = .main, do callback: @escaping (Value) -> Void) -> Future<Value> {
        onSuccessCallbacks.append((queue, callback))
        
        // If a result has already been set, call the success callback directly
        // only if the result is a success
        result.map { result in
            if case Result.success(let value) = result {
                switch queue {
                case .main: DispatchQueue.main.async { callback(value) }
                case .background: callback(value)
                }
            }
        }
        return self
    }
    
    @discardableResult
    public func onFailure(on queue: Queue = .main, do callback: @escaping (Swift.Error) -> Void) -> Future<Value> {
        onFailureCallbacks.append((queue, callback))
        
        // If a result has already been set, call the failure callback directly
        // only if the result is a failure
        result.map { result in
            if case Result.failure(let error) = result {
                switch queue {
                case .main: DispatchQueue.main.async { callback(error) }
                case .background: callback(error)
                }
            }
        }
        return self
    }
    
    private func report(result: Result<Value, Swift.Error>) {
        for (queue, callback) in callbacks {
            switch queue {
            case .main: DispatchQueue.main.async { callback(result) }
            case .background: callback(result)
            }
        }
        if case Result.success(let value) = result {
            onSuccessCallbacks.forEach { queue, callback in
                switch queue {
                case .main: DispatchQueue.main.async { callback(value) }
                case .background: callback(value)
                }
            }
        }
        if case Result.failure(let error) = result {
            onFailureCallbacks.forEach { queue, callback in
                switch queue {
                case .main: DispatchQueue.main.async { callback(error) }
                case .background: callback(error)
                }
            }
        }
    }
}

public class Promise<Value>: Future<Value> {
    public init(value: Value? = nil) {
        super.init()
        
        // If a value is already given in input, we can report the value directly
        result = value.map { value in Result.success(value) }
    }
    
    public func resolve(with value: Value) {
        result = .success(value)
    }
    
    public func reject(with error: Swift.Error) {
        result = .failure(error)
    }
}
