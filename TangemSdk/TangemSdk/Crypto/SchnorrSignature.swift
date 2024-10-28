//
//  SchnorrSignature.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk_secp256k1

public struct SchnorrSignature {
    private let secp256k1 = Secp256k1Utils()
    private let signature: Data

    public init(with signature: Data) throws {
        guard signature.count == 64 else {
            throw TangemSdkError.cryptoUtilsError("Signature size must be equal to 64 bytes")
        }

        self.signature = signature
    }

    /// Verify with sha256 hash function
    public func verify(with publicKey: Data, message: Data) throws -> Bool {
        return try verify(with: publicKey, hash: message.getSha256())
    }

    public func verify(with publicKey: Data, hash: Data) throws -> Bool {
        return try secp256k1.verifySchnorrSignature(signature, publicKey: publicKey, hash: hash)
    }
}
