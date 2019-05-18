//
//  Endpoint.swift
//  NetworkKit
//
//  Created by Fabio Ferrero on 18/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public struct Endpoint {
    var url: String
    var method: HTTPMethod
    
    public init(url: String, method: HTTPMethod = .get) {
        self.url = url
        self.method = method
    }
}
