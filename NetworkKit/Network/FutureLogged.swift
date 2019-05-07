//
//  FutureLogged.swift
//  Network
//
//  Created by Fabio Ferrero on 02/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation
import FutureKit

extension Future where Value == Data {
    public func logged() -> Future<Value> {
        return performing { data in
            if let outputDescription = String(data: data, encoding: .utf8) {
                print(outputDescription)
            } else {
                print("Cannot log data: [\(data)]")
            }
        }
    }
}
