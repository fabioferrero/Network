//
//  Encoder&Decoder.swift
//  Network
//
//  Created by Fabio Ferrero on 19/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

protocol DataEncoder {
    func encode<Input: Encodable>(_ value: Input) throws -> Data
    func string<Input: Encodable>(for value: Input) -> String?
}

protocol DataDecoder {
    func decode<Output: Decodable>(_ type: Output.Type, from data: Data) throws -> Output
}

extension DataEncoder {
    func string<Input>(for value: Input) -> String? where Input : Encodable {
        guard let data: Data = try? self.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
