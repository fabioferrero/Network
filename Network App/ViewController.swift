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
    
    private let loader: UIActivityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    private let manager = PhotoLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader.hidesWhenStopped = true
        view.addSubview(loader)
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loader.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 100).isActive = true
    }
    
    @IBAction func callButtonTapped() {
        // In foreground (UI stuff happens)
        loader.startAnimating()
        manager.loadRandomPhoto().observe { result in
            self.loader.stopAnimating()
            
            switch result {
            case .success(let photo):
                self.imageView.image = photo
            case .failure(let error):
                let alert = Alert(title: "Error", message: error.localizedDescription)
                alert.show(from: self)
            }
        }
        
        // In background (no UI needed)
        manager.loadPhotoList()
            .onSuccess(on: .background) { photoList in
                Logger.log(.debug, message: "Got \(photoList.count) photos")
            }
            .onFailure(on: .background) { error in
                Logger.log(.error, message: "Retrieved error: \(error.localizedDescription)")
            }
    }
    
    @IBAction func switchDidChanged(_ sender: UISwitch) {
        shouldFail = sender.isOn
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
