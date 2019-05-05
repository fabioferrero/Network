//
//  SecurityManager.swift
//  Network
//
//  Created by Fabio Ferrero on 19/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public protocol SecurityManager {
    func encrypt(data: Data) -> Data
    func decrypt(data: Data) -> Data
}
