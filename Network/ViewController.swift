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
        
        func foo() {
            print("foo!")
        }
    }
    
    struct NewPost: Encodable {
        var userId: Int
        var title: String
        var body: String
    }
    
    // I define my custom service as a struct or class conforming to the Service
    // protocol, so that it contains the proper service `url` and define the
    // corresponding `Input` and `Output` types, that must be, in order,
    // conforming to the `Encodable` and `Decodable` protocols.
    struct MyService: Service {
        
        static var url: String = "https://jsonplaceholder.typicode.com/posts"
        
        typealias Input = NewPost
        typealias Output = Post
    }
    
    @IBAction func callButtonTapped() {
        callMyService()
    }
    
    func callMyService() {
        let newPost = NewPost(userId: 3, title: "Title", body: "Body")
        let request = Network.Request<MyService>(payload: newPost)
        
        Network.shared.callService(with: request) { response in
            switch response {
            case .OK(let thePostThatYouWereWaitingFor):
                self.use(thePostThatYouWereWaitingFor)
                thePostThatYouWereWaitingFor.foo()
            case .KO(let error): Alert.shared.show(error)
            }
        }
    }
    
    func use(_ any: Any) {
        print("Using:", String(describing: any))
    }
}

final class Alert {
    
    static let shared: Alert = Alert()
    private init() {}
    
    func show(_ any: Any) {
        print("Alert:", String(describing: any))
    }
}
