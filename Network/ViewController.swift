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
    
    @IBAction func callButtonTapped() {
        
        let serviceURL = "https://jsonplaceholder.typicode.com/posts"

        let post = NewPost(userId: 14, title: "NewPost", body: "Lorem Ipsum Dolor sit Amet")

        let request = Network.Request(serviceUrl: serviceURL, payload: post)

        Network.shared.callService(withRequest: request) { (response: Network.Response<Post>) in
            switch response {
            case .OK(let post): print(post)
            case .KO(let error): print(error.message)
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
