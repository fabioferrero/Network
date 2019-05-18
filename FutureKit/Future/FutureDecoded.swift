//
//  FutureDecoded.swift
//  Network
//
//  Created by Fabio Ferrero on 27/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public extension Future where Value == Data {
    func decoded<NewValue: Decodable>(to type: NewValue.Type = NewValue.self) -> Future<NewValue> {
        return transformed { value in
            return try JSONDecoder().decode(type, from: value)
        }
    }
    
    func decoded<NewValue: Decodable>() -> Future<NewValue> {
        return transformed { value in
            return try JSONDecoder().decode(NewValue.self, from: value)
        }
    }
}
