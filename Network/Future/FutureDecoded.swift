//
//  FutureDecoded.swift
//  Network
//
//  Created by Fabio Ferrero on 27/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

extension Future where Value == Data {
    func decoded<NewValue: Decodable>() -> Future<NewValue> {
        return transformed { value in
            return try JSONDecoder().decode(NewValue.self, from: value)
        }
    }
}
