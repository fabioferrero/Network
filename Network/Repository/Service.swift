//
//  Service.swift
//  Network
//
//  Created by Fabio Ferrero on 10/06/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

// TODO: Service Extension
// Add an extension to the `Service` protocol so that it can return a Request
// ready with itself.
protocol Service {
    associatedtype Input: Encodable
    associatedtype Output: Decodable
    
    static var url: String { get }
}
