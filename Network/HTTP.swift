//
//  HTTP.swift
//  Network
//
//  Created by Fabio Ferrero on 19/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    case patch
}

extension HTTPMethod: CustomStringConvertible {
    var description: String {
        return self.rawValue.uppercased()
    }
}

enum HTTPStatusCode: Int {
    case ok                     = 200
    case created                = 201
    case accepted               = 202
    case noContent              = 204
    case movedPermanently       = 301
    case found                  = 302
    case seeOther               = 303
    case notModified            = 304
    case temporaryRedirect      = 307
    case badRequest             = 400
    case unauthorized           = 401
    case forbidden              = 403
    case notFound               = 404
    case methodNotAllowed       = 405
    case notAcceptable          = 406
    case preconditionFailed     = 412
    case unsupportedMedia       = 415
    case internalServerError    = 500
    case notImplemented         = 501
}
