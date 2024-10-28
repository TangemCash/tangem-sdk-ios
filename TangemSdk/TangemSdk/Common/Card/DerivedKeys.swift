//
//  DerivedKeys.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 04.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// We can't use CodingKeyRepresentable because of iOS 15 version
public struct DerivedKeys: JSONStringConvertible {
    public private(set) var keys: [DerivationPath:ExtendedPublicKey]

    public init(keys: [DerivationPath : ExtendedPublicKey]) {
        self.keys = keys
    }

    public subscript(_ path: DerivationPath) -> ExtendedPublicKey? {
        get {
            return keys[path]
        }
        set(newValue) {
          keys[path] = newValue
        }
    }
}

extension DerivedKeys: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringDictionary = try container.decode([String: ExtendedPublicKey].self)

        let keysDictionary: [DerivationPath: ExtendedPublicKey] = try stringDictionary.reduce(into: [:]) { partialResult, item in
            let path = try DerivationPath(rawPath: item.key)
            partialResult[path] = item.value
        }

        self.init(keys: keysDictionary)
    }

    public func encode(to encoder: Encoder) throws {
        let stringDictionary = keys.reduce(into: [:]) { partialResult, item in
            partialResult[item.key.rawPath] = item.value
        }

        var container = encoder.singleValueContainer()
        try container.encode(stringDictionary)
    }
}

extension DerivedKeys: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (DerivationPath, ExtendedPublicKey)...) {
        let dictionary = elements.reduce(into: [:]) { partialResult, item in
            partialResult[item.0] = item.1
        }

        self.init(keys: dictionary)
    }
}
