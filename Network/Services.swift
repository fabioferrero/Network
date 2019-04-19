//
//  Services.swift
//  Network
//
//  Created by Fabio Ferrero on 19/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

struct EmptyPayload: Codable {}

// MARK: - App Models

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

enum Services {
    static let createNewPost = CreateNewPost.self
    static let errorService = ErrorService.self
}

struct CreateNewPost: DataService {
    typealias Input = NewPost
    typealias Output = Post
    
    static var method: HTTPMethod = .post
    static var path: String = "https://jsonplaceholder.typicode.com/posts"
}

struct ErrorService: DataService {
    typealias Input = EmptyPayload
    typealias Output = EmptyPayload
    
    static var method: HTTPMethod = .post
    static var path: String = "https://fakeservice.error/"
}
