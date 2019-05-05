//
//  Services.swift
//  Network
//
//  Created by Fabio Ferrero on 19/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

enum Services {
    static let createNewPost = CreateNewPost.self
    static let errorService = ErrorService.self
}

struct CreateNewPost: IOService {
    typealias Input = NewPost
    typealias Output = Post
    
    static var method: HTTPMethod = .post
    static var path: String = "https://jsonplaceholder.typicode.com/posts"
}

struct ErrorService: IOService {
    typealias Input = EmptyPayload
    typealias Output = EmptyPayload
    
    static var method: HTTPMethod = .post
    static var path: String = "https://fakeservice.error/"
}

struct GetRandomPhoto: DataService {
    typealias Output = Photo
    static var path: String = "https://picsum.photos/480"
}

struct GetPhotoList: DataService {
    typealias Output = [Photo]
    static var path: String = "https://picsum.photos/v2/list"
}
