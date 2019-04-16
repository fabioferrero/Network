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
    func callService<S: Service>(_ service: S, input: S.Input, onCompletion: @escaping (_ response: Result<S.Output, Error>) -> Void)
}
