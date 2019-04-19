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
    var loader: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    var network: Network = Network.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader.hidesWhenStopped = true
        view.addSubview(loader)
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loader.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 100).isActive = true
    }
    
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
    struct CreateNewPost: Service {
        static var method: HTTPMethod = .post
        static var path: String = "https://jsonplaceholder.typicode.com/posts"
        
        typealias Input = NewPost
        typealias Output = Post
    }
    
    struct ErrorService: Service {
        static var method: HTTPMethod = .post
        static var path: String = "https://fakeservice.error/"
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
        network.call(service: ErrorService(), input: ErrorService.Input()) { result in
            switch result {
            case .success:
                let alert = Alert(title: "Success", message: "It was actually a real success.")
                alert.show(from: self)
            case .failure(error: let error):
                let alert = Alert(title: "Error", message: error.localizedDescription)
                alert.show(from: self)
            }
        }
    }
    
    private var backgroundPost: Post?
    
    func callMyService() {
        let newPost = NewPost(userId: 3, title: "Title", body: "Body")
        loader.startAnimating()
        network.call(service: CreateNewPost(), input: newPost) { [weak self] result in
            guard let self = self else { return }
            self.loader.stopAnimating()
            switch result {
            case .success(let thePostThatYouWereWaitingFor):
                self.use(thePostThatYouWereWaitingFor)
                thePostThatYouWereWaitingFor.foo()
            case .failure(let error):
                let alert = Alert(title: "Error", message: error.localizedDescription)
                alert.show(from: self)
            }
        }
        let backgroundPost = NewPost(userId: 0, title: "Background!", body: "Super cool")
        network.call(service: CreateNewPost(), input: backgroundPost, onQueue: .background) { result in
            switch result {
            case .success(let backgroundPost):
                self.backgroundPost = backgroundPost
            case .failure(let error):
                let alert = Alert(title: "Error", message: error.localizedDescription)
                alert.show(from: self)
            }
        }
    }
    
    func use(_ post: Post) {
        Logger.log(.verbose, message: "Using: \(post)")
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
