//
//  Secp256k1Key.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.12.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk_secp256k1

public struct Secp256k1Key {
    private let secp256k1 = Secp256k1Utils()
    private let secp256k1PubKey: secp256k1_pubkey
    
    public init(with data: Data) throws {
        secp256k1PubKey = try secp256k1.parsePublicKey(data)
    }

    public init(with signature: Secp256k1Signature.Extended, hash: Data) throws {
        secp256k1PubKey = try secp256k1.recoverPublicKey(signatureCoponents: signature.components, hash: hash)
    }

    public init(with signature: Secp256k1Signature.Extended, message: Data) throws {
        try self.init(with: signature, hash: message.getSha256())
    }

    public func compress() throws -> Data {
        var pubkey = secp256k1PubKey
        return try secp256k1.serializePublicKey(&pubkey, compressed: true)
    }
    
    public func decompress() throws -> Data {
        var pubkey = secp256k1PubKey
        return try secp256k1.serializePublicKey(&pubkey, compressed: false)
    }
}
