//
//  FutureTransformed.swift
//  Network
//
//  Created by Fabio Ferrero on 27/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public extension Future {
    func transformed<NewValue>(with closure: @escaping (Value) throws -> NewValue) -> Future<NewValue> {
        return chained { value in
            return try Promise(value: closure(value))
        }
    }
}
