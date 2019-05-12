//
//  Encoder&Decoder.swift
//  Network
//
//  Created by Fabio Ferrero on 19/04/2019.
//  Copyright © 2019 Fabio Ferrero. All rights reserved.
//

import Foundation

public protocol DataEncoder {
    func encode<Input: Encodable>(_ value: Input) throws -> Data
    func string<Input: Encodable>(for value: Input) -> String?
}

public protocol DataDecoder {
    func decode<Output: Decodable>(_ type: Output.Type, from data: Data) throws -> Output
    func string(from data: Data) -> String?
}

extension DataEncoder {
    func string<Input>(for value: Input) -> String? where Input : Encodable {
        guard let data: Data = try? self.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension DataDecoder {
    func string(from data: Data) -> String? {
        guard let json: Any = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        guard let jsonData: Data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]) else { return nil }
        return String(data: jsonData, encoding: String.Encoding.utf8)
    }
}
