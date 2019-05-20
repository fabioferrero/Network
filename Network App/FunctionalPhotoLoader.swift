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

/// This is an example class that, in different versions of the same method,
/// shows the advantages ov using a functional network approach
struct FunctionalPhotoLoader {
    
    /// A networking function. It simply takes an Endpoint as input, and
    /// returns a Future<Data> as output. The key point here is that it is
    /// independent from the actual implementation under the hood.
    private let networking: Networking
    
    // We pass a default implementation to the Loader, just for easy-to-use API
    init(with networking: @escaping Networking = Network.default.request) {
        self.networking = networking
    }
    
    // Here, calls the networking function as usual
    func loadPhotoListV1(numberOfPhotos: Int) -> Future<[Photo]> {
        let endpoint = Endpoint.photoList(numberOfPhotos: numberOfPhotos)
        return networking(endpoint).decoded()
    }
    
    // Here, we combine an endpoint to the networking closure, just for demonstration
    func loadPhotoListV2(numberOfPhotos: Int) -> Future<[Photo]> {
        let endpoint = Endpoint.photoList(numberOfPhotos: numberOfPhotos)
        let networking = combine(endpoint, with: self.networking)
        
        // Our new networking function can now be called without
        // having to supply any argument at the call site.
        return networking().decoded()
    }
    
    // Here, we chain the creation of a Endpoint with che calling closure
    func loadPhotoListV3(numberOfPhotos: Int) -> Future<[Photo]> {
        let networking = chain(Endpoint.photoList, to: self.networking)
        return networking(numberOfPhotos).decoded()
    }
    
    // Here, we also chain the calling closure with the instance metod of decoding
    func loadPhotoListV4(numberOfPhotos: Int) -> Future<[Photo]> {
        let networking = chain(Endpoint.photoList, to: self.networking)
        return chain(networking, to: Future.decoded)(numberOfPhotos)
    }
}
