//
//  Environment.swift
//  ReplyNative
//
//  Created by Fabio Ferrero on 09/06/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

/// Represents the current environment with all its environment variables
enum Environment {
    case LOG_VERBOSE
    case LOG_DEBUG
    case LOG_INFO
    case LOG_WARNING
    case LOG_ERROR
    case LOG_SEVERE
    
    /// The value corresponding to the specified environment variable
    var value: String? {
        let key = String(describing: self)
        return ProcessInfo.processInfo.environment[key]
    }
    
    /// Returns if the specified environment variable value is equal to "enable"
    var isEnabled: Bool {
        return self.value == "enable"
    }
}
