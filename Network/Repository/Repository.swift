//
//  Repository.swift
//  Network
//
//  Created by Fabio Ferrero on 17/05/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

/// Defines a general interface on witch any DataService must rely on.
protocol Repository {
    func perform<S: Service>(_ request: Request<S>, onCompletion: @escaping (Response<S.Output>) -> Void)
}

struct Request<S: Service> {
    var payload: S.Input
}

enum Response<Output: Decodable> {
    case OK(response: Output)
    case KO(error: Error)
}
