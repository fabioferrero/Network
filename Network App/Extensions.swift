//
//  Extensions.swift
//  Network App
//
//  Created by Fabio Ferrero on 18/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import UIKit

extension UIImage {
    enum Error: Swift.Error, LocalizedError {
        case imageNotCreated
        case mockedError
        
        var errorDescription: String? {
            switch self {
            case .imageNotCreated: return "Impossible to create image"
            case .mockedError: return "The image was not so great!"
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
