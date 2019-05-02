//
//  FutureError.swift
//  Network
//
//  Created by Fabio Ferrero on 02/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

extension Future {
    enum Error: Swift.Error {
        case cannotLog
        
        var localizedDescription: String {
            switch self {
            case .cannotLog: return "Impossible to log data"
            }
        }
    }
}
