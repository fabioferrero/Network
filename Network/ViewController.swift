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
        
        typealias Input = NewPost
        typealias Output = Post
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
            case .OK(let post): print("NewPost correctly created: \(post)")
            case .KO(let error): print(error.description)
            }
        }
    }
}
