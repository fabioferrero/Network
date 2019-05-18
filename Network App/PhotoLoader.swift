//
//  PhotoLoader.swift
//  Network App
//
//  Created by Fabio Ferrero on 17/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation
import NetworkKit
import FutureKit

var shouldFail: Bool = false

struct PhotoLoader {
    private var network: Network
    
    init(with network: Network = Network.default) {
        self.network = network
    }
    
    func loadRandomPhoto() -> Future<UIImage> {
        let endpoint = Network.Endpoint(url: "https://picsum.photos/480")
        return network.request(endpoint).transformed(with: UIImage.imageFromData)
    }
    
    func loadPhotoList() -> Future<[Photo]> {
        let endpoint = Network.Endpoint(url: "https://picsum.photos/v2/list?limit=5")
        return network.request(endpoint).decoded()
    }
}

extension UIImage {
    enum Error: Swift.Error, LocalizedError {
        case imageNotCreated
        case mockedError
        
        var errorDescription: String? {
            switch self {
            case .imageNotCreated: return "Impossible to create image"
            case .mockedError: return "The image was not so great"
            }
        }
    }
    
    static func imageFromData(_ data: Data) throws -> UIImage {
        if shouldFail {
            throw UIImage.Error.mockedError
        }
        if let image = UIImage(data: data) {
            return image
        } else {
            throw UIImage.Error.imageNotCreated
        }
    }
}
