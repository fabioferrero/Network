//
//  DataService.swift
//  Network
//
//  Created by Fabio Ferrero on 17/05/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

enum DataService {
    
    static var networkRepository: Repository = Network.shared
    static var repository: Repository = MockRepository()
    
    static var mocked = MockedDataService()
}
