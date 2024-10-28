//
//  StringCodable.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol StringCodable: Codable & RawRepresentable where RawValue == String {}

extension StringCodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercasingFirst()
        
        if let value = Self(rawValue: stringValue) {
            self = value
        } else {
            throw TangemSdkError.decodingFailed("Failed to decode \(String(describing: type(of:Self.self)))")
        }
    }
}
