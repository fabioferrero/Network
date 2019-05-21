//
//  Models.swift
//  Network App
//
//  Created by Fabio Ferrero on 05/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

struct Photo: Decodable {
    var id: String
    var author: String
    var width: Int
    var height: Int
    var url: String
    var download_url: String
}
