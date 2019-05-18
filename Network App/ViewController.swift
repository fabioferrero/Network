//
//  ViewController.swift
//  Network
//
//  Created by Fabio Ferrero on 27/02/18.
//  Copyright © 2018 Fabio Ferrero. All rights reserved.
//

import UIKit
import FutureKit
import NetworkKit

final class ViewController: UIViewController {
    
    @IBOutlet private weak var errorSwitch: UISwitch!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var loader: UIActivityIndicatorView!
    
    private let manager = FunctionalPhotoLoader()
    
    typealias PhotoListLoading = () -> Future<[Photo]>
    var photoListLoading: PhotoListLoading!
    
    typealias RandomPhotoLoading = () -> Future<Data>
    var randomPhotoLoading: RandomPhotoLoading!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This should be done by external Coordinator, so that this view controller
        // knows nothing about internal networking logic
        photoListLoading = combine(3, with: Network.default.photoListNetworking)
        randomPhotoLoading = combine(1080, with: Network.default.randomSquarePhotoNetworking)
    }
    
    @IBAction func callButtonTapped() {
        // In foreground (UI stuff happens)
        loader.startAnimating()
        randomPhotoLoading().transformed(with: UIImage.imageFromData).observe { [weak self] result in
            guard let self = self else { return }
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
        manager.loadPhotoListV4(numberOfPhotos: 5)
            .onSuccess(on: .background) { photoList in
                Logger.log(.debug, message: "Got \(photoList.count) photos")
            }
            .onFailure(on: .background) { error in
                Logger.log(.error, message: "Retrieved error: \(error.localizedDescription)")
            }
        
        photoListLoading().observe(on: .background) { (result) in
            switch result {
            case .success(let photoList):
                Logger.log(.debug, message: "Got \(photoList.count) photos")
            case .failure(let error):
                Logger.log(.error, message: "Retrieved error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func switchDidChanged(_ sender: UISwitch) {
        shouldFail = sender.isOn
    }
}

/// Small utility to present UIAlertController
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
