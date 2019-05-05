//
//  Service.swift
//  NetworkKit
//
//  Created by Fabio Ferrero on 05/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public protocol DataService {
    associatedtype Output: Decodable
    static var path: String { get }
}

extension DataService {
    static var method: HTTPMethod { return .get }
}

public protocol IOService: DataService {
    associatedtype Input: Encodable
    static var method: HTTPMethod { get }
}
