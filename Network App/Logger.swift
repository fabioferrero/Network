//
//  Logger.swift
//  ReplyNative
//
//  Created by Fabio Ferrero on 09/06/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

final class Logger {
    
    private init() {}
    
    static func log(_ logLevel: LogLevel, message: String, file: String = #file, function: String = #function, line: Int = #line) {
    
        #if DEBUG
        if logLevel.isEnabled {
            var filename = (file as NSString).lastPathComponent
            filename = filename.components(separatedBy: ".")[0]
            
            print("\(logLevel.symbol)\t[\(logLevel.code)] @ \(filename).\(function) (\(line))\n\t\(message)")
        }
        #endif
    }
 
    enum LogLevel {
        
        case verbose
        case debug
        case info
        case warning
        case error
        case severe
        
        var symbol: String {
            switch self {
            case .verbose: return "📣"
            case .debug: return "🚀"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .severe: return "🛑"
            }
        }
        
        var code: Character {
            return String(describing: self).uppercased().first!
        }
        
        var isEnabled: Bool {
            return Environment(for: self).isEnabled
        }
    }
}

private extension Environment {
    
    init(for logLevel: Logger.LogLevel) {
        switch logLevel {
        case .verbose: self = .LOG_VERBOSE
        case .debug: self = .LOG_DEBUG
        case .info: self = .LOG_INFO
        case .warning: self = .LOG_WARNING
        case .error: self = .LOG_ERROR
        case .severe: self = .LOG_SEVERE
        }
    }
}
