//
//  ViewController.swift
//  Network
//
//  Created by Fabio Ferrero on 27/02/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var errorSwitch: UISwitch!
    
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
    
    // I define my custom service as a struct or class conforming to the Service
    // protocol, so that it contains the proper service `url` and define the
    // corresponding `Input` and `Output` types, that must be, in order,
    // conforming to the `Encodable` and `Decodable` protocols.
    struct MyService: NetworkService {
        
        static var url: String = "https://jsonplaceholder.typicode.com/posts"
        
        typealias Input = NewPost
        typealias Output = Post
    }
    
    struct ErrorService: NetworkService {
        static var url: String = "https://fakeservice.error/"
        struct Input: Encodable {};
        struct Output: Decodable {};
    }
    
    @IBAction func callButtonTapped() {
        if errorSwitch.isOn {
            callErrorService()
        } else {
            callMyService()
        }
    }
    
    func callErrorService() {
        let request = Network.Request<ErrorService>(payload: ErrorService.Input())
        
        Network.shared.callService(with: request) { response in
            switch response {
            case .OK:
                let alert = Alert(title: "Success", message: "It was actually a real success.")
                alert.show(from: self)
            case .KO(let error):
                let alert = Alert(title: "Error", message: error.description)
                alert.show(from: self)
            }
        }
    }
    
    func callMyService() {
        let newPost = NewPost(userId: 3, title: "Title", body: "Body")
        let request = Network.Request<MyService>(payload: newPost)
        
        Network.shared.callService(with: request) { response in
            switch response {
            case .OK(let thePostThatYouWereWaitingFor):
                self.use(thePostThatYouWereWaitingFor)
                thePostThatYouWereWaitingFor.foo()
            case .KO(let error):
                let alert = Alert(title: "Error", message: error.description)
                alert.show(from: self)
            }
        }
    }
    
    func use(_ any: Any) {
        Logger.log(.verbose, message: "Using: \(any)")
    }
}

class Alert {
    
    let title: String
    let message: String
    
    private var alertController: UIAlertController
    
    init(title: String, message: String) {
        
        self.title = title
        self.message = message
        
        self.alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    
    func show(from viewController: UIViewController) {
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        
        viewController.showDetailViewController(alertController, sender: nil)
    }
}
