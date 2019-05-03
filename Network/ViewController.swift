//
//  ViewController.swift
//  Network
//
//  Created by Fabio Ferrero on 27/02/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet private weak var errorSwitch: UISwitch!
    @IBOutlet private weak var imageView: UIImageView!
    
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
    
    @IBAction func callButtonTapped() {
        
        struct GetRandomPhoto: DataService {
            typealias Output = Photo
            static var path: String = "https://picsum.photos/480"
        }
        
        loader.startAnimating()
        URLSession.shared.request(for: GetRandomPhoto()).transformed(with: UIImage.imageFromData)
            .onSuccess { photo in
                self.loader.stopAnimating()
                self.imageView.image = photo
            }.onFailure { error in
                self.loader.stopAnimating()
                let alert = Alert(title: "Error", message: error.localizedDescription)
                alert.show(from: self)
            }
        
        // In background
        struct Photo: Decodable {
            var id: String
            var author: String
            var width: Int
            var height: Int
            var url: String
            var download_url: String
        }
        
        struct GetPhotoList: DataService {
            typealias Output = [Photo]
            static var path: String = "https://picsum.photos/v2/list"
        }
        
        network.request(service: GetPhotoList())
            .logged()
            .decoded(to: [Photo].self)
            .observe(on: .background) { _ in
            
        }
    }

    func callMyService() {
        let newPost = NewPost(userId: 3, title: "Title", body: "Body")
        loader.startAnimating()
        network.call(service: Services.createNewPost, input: newPost) { [weak self] result in
            guard let self = self else { return }
            self.loader.stopAnimating()
            switch result {
            case .success(let thePostThatYouWereWaitingFor):
                thePostThatYouWereWaitingFor.foo()
            case .failure(let error):
                let alert = Alert(title: "Error", message: error.localizedDescription)
                alert.show(from: self)
            }
        }
    }
}

extension UIImage {
    enum Error: Swift.Error {
        case imageNotCreated
        
        var localizedDescription: String {
            switch self {
            case .imageNotCreated: return "Impossible to create image"
            }
        }
    }
    
    static func imageFromData(_ data: Data) throws -> UIImage {
        if let image = UIImage(data: data) {
            return image
        } else {
            throw UIImage.Error.imageNotCreated
        }
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
