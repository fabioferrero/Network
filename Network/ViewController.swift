//
//  ViewController.swift
//  Network
//
//  Created by Fabio Ferrero on 27/02/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    struct Post: Decodable {
        var userId: Int
        var id: Int
        var title: String
        var body: String
    }
    
    struct NewPost: Encodable {
        var userId: Int
        var title: String
        var body: String
    }
    
    var index: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    struct MyService: Service {
        
        static var url: String = "https://jsonplaceholder.typicode.com/posts"
        
        struct Input: Encodable {
            var userId: Int
            var title: String
            var body: String
        }
        
        struct Output: Decodable {
            var userId: Int
            var id: Int
            var title: String
            var body: String
        }
    }
    
    @IBAction func callButtonTapped() {
        
        let input = MyService.Input(
            userId: 14,
            title: "NewPost",
            body: "Lorem Ipsum Dolor sit Amet"
        )
        
        let request = Network.Request<MyService>(payload: input)
        
        Network.shared.callService(withNewRequest: request) { response in
            switch response {
            case .OK(let post): print(post)
            case .KO(let error): print(error.description)
            }
        }
        
//        for i in index..<(index + 5) {
//            guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(i)") else { return }
//
//            Network.shared.callService(withURL: url) { (response: Network.Response<Post>) in
//                switch response {
//                case .OK(let post): print(post)
//                case .KO(let error): print(error.message)
//                }
//            }
//        }
//
//        index += 5
    }
}
