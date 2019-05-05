//
//  Models.swift
//  Network App
//
//  Created by Fabio Ferrero on 05/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

struct EmptyPayload: Codable {}

struct Post: Decodable {
    var userId: Int
    var id: Int
    var title: String
    var body: String
    
    func foo() {
        Logger.log(.verbose, message: "foo on \(String(describing: self))! foo!")
    }
}

struct NewPost: Encodable {
    var userId: Int
    var title: String
    var body: String
}

struct Photo: Decodable {
    var id: String
    var author: String
    var width: Int
    var height: Int
    var url: String
    var download_url: String
}
