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
    
    func loadRandomSquarePhoto(size: Int) -> Future<UIImage> {
        let endpoint = Endpoint(url: "https://picsum.photos/\(size)")
        return network.request(endpoint).transformed(with: UIImage.imageFromData)
    }
    
    func loadRandomPhoto(width: Int, height: Int) -> Future<UIImage> {
        let endpoint = Endpoint(url: "https://picsum.photos/\(width)/\(height)")
        return network.request(endpoint).transformed(with: UIImage.imageFromData)
    }
    
    func loadPhotoList() -> Future<[Photo]> {
        let endpoint = Endpoint(url: "https://picsum.photos/v2/list?limit=5")
        return network.request(endpoint).decoded()
    }
}

typealias Networking = (Endpoint) -> Future<Data>

struct FunctionalPhotoLoader {
    private let networking: Networking
    
    init(with networking: @escaping Networking = Network.default.request) {
        self.networking = networking
    }
    
    func loadPhotoList(numberOfPhotos: Int) -> Future<[Photo]> {
        let endpoint = Endpoint.photoList(numberOfPhotos: numberOfPhotos)
        return networking(endpoint).decoded()
    }
    
    func loadPhotoListV1(numberOfPhotos: Int) -> Future<[Photo]> {
        let endpoint = Endpoint.photoList(numberOfPhotos: numberOfPhotos)
        let networking = combine(endpoint, with: self.networking)
        
        // Our new networking function can now be called without
        // having to supply any argument at the call site.
        return networking().decoded()
    }
    
    func loadPhotoListV2(numberOfPhotos: Int) -> Future<[Photo]> {
        let networking = chain(Endpoint.photoList, to: self.networking)
        return networking(numberOfPhotos).decoded()
    }
    
    func loadPhotoListV3(numberOfPhotos: Int) -> Future<[Photo]> {
        let networking = chain(Endpoint.photoList, to: self.networking)
        return chain(networking, to: Future.decoded)(numberOfPhotos)
    }
}

extension Endpoint {
    static func photoList(numberOfPhotos: Int) -> Endpoint {
        return Endpoint(url: "https://picsum.photos/v2/list?limit=\(numberOfPhotos)")
    }
}

extension Network {
    var photoListNetworking: (_ numberOfPhotos: Int) -> Future<[Photo]> {
        let networking = chain(Endpoint.photoList, to: request)
        return chain(networking, to: Future.decoded)
    }
}

// Turns an (A) -> B function into a () -> B function,
// by using a constant value for A.
func combine<A, B>(_ value: A, with closure: @escaping (A) -> B) -> () -> B {
    return { closure(value) }
}

// Turns an (A) -> B and a (B) -> C function into a
// (A) -> C function, by chaining them together.
func chain<A, B, C>(_ inner: @escaping (A) -> B, to outer: @escaping (B) -> C) -> (A) -> C {
    return { outer(inner($0)) }
}

// Turns an (A) -> B and a (B) -> () -> C (a.k.a. instance methods) function into a
// (A) -> C function, by chaining them together.
func chain<A, B, C>(_ inner: @escaping (A) -> B, to outer: @escaping (B) -> () -> C) -> (A) -> C {
    return { outer(inner($0))() }
}
