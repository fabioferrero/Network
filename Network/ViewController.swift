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
    
    struct MyService: Service {
        
        static var url: String = "https://jsonplaceholder.typicode.com/posts"
        
        typealias Input = NewPost
        typealias Output = Post
    }
    
    @IBAction func callButtonTapped() {
        preferredBehavior()
    }
    
    func preferredBehavior() {
        let request = Network.Request<MyService>(input: NewPost(userId: 3, title: "Title", body: "Body"))
        
        Network.shared.callService(with: request) { response in
            switch response {
            case .OK(let theObjectThatIsNeeded): self.use(theObjectThatIsNeeded)
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
