//
//  Repository.swift
//  Network
//
//  Created by Fabio Ferrero on 17/05/2018.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import Foundation

protocol Repository {
    func perform(request: Request, completion: @escaping ((Response) -> Void))
}
