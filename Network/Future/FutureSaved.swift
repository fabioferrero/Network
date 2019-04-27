//
//  FutureSaved.swift
//  Network
//
//  Created by Fabio Ferrero on 27/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

protocol Savable {}

protocol Database {
    func save<S: Savable>(_ savable: S, callback: @escaping (Result<S, Error>) -> Void)
}

extension Future where Value: Savable {
    func saved(in database: Database) -> Future<Value> {
        return chained { value in
            let promise = Promise<Value>()
            
            database.save(value) { result in
                switch result {
                case .success(let value):
                    promise.resolve(with: value)
                case .failure(let error):
                    promise.reject(with: error)
                }
            }
            
            return promise
        }
    }
}
