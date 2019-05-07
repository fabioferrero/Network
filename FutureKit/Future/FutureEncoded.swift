//
//  FutureEncoded.swift
//  FutureKit
//
//  Created by Fabio Ferrero on 05/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public extension Encodable {
    func encoded() -> Future<Data> {
        let promise = Promise<Data>()
        do { promise.resolve(with: try JSONEncoder().encode(self)) }
        catch { promise.reject(with: error)}
        return promise
    }
}
