//
//  DataService.swift
//  Network
//
//  Created by Fabio Ferrero on 17/05/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

enum DataService {
    
    static var repository: Repository {
        return Session.default.repository
    }
    
    static var fake: FakeDataService {
        return FakeDataService(repository: repository)
    }
}
