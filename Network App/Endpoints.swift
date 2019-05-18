//
//  Endpoints.swift
//  Network App
//
//  Created by Fabio Ferrero on 18/05/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation
import NetworkKit
import FutureKit

extension Endpoint {
    static func photoList(numberOfPhotos: Int) -> Endpoint {
        return Endpoint(url: "https://picsum.photos/v2/list?limit=\(numberOfPhotos)")
    }
    
    static func randomSquarePhoto(size: Int) -> Endpoint {
        return Endpoint(url: "https://picsum.photos/\(size)")
    }
}

extension Network {
    var photoListNetworking: (_ numberOfPhotos: Int) -> Future<[Photo]> {
        let networking = chain(Endpoint.photoList, to: request)
        return chain(networking, to: Future.decoded)
    }
    
    var randomSquarePhotoNetworking: (_ size: Int) -> Future<Data> {
        let networking = chain(Endpoint.randomSquarePhoto, to: request)
        return networking
    }
}
