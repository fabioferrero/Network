//
//  FutureLogged.swift
//  Network
//
//  Created by Fabio Ferrero on 02/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

extension Future where Value == Data {
    func logged(with message: String? = nil) -> Future<Value> {
        return applying { data in
            if let outputDescription = String(data: data, encoding: .utf8) {
                let message: String = message ?? ""
                Logger.log(.info, message: message + "\n\(outputDescription)")
            } else {
                Logger.log(.warning, message: "Cannot log data: [\(data)]")
            }
        }
    }
}
