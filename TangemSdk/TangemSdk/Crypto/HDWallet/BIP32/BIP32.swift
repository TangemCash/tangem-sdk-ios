//
//  BIP32.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 04.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
struct BIP32 {
    @available(iOS 13.0, *)
    /// Generate an extended private key from the seed.
    /// - Parameters:
    ///   - seed: The seed to use
    ///   - curve: The curve to use
    /// - Returns: The `ExtendedPrivateKey`
    func makeMasterKey(from seed: Data, curve: EllipticCurve) throws -> ExtendedPrivateKey {
        // The seed must be between 128 and 512 bits
        guard 16...64 ~= seed.count else {
            throw HDWalletError.invalidSeed
        }

        guard let keyData = curve.hmacKey.rawValue.data(using: .utf8) else {
            throw HDWalletError.invalidHMACKey
        }

        let symmetricKey = SymmetricKey(data: keyData)
        let authenticationCode = HMAC<SHA512>.authenticationCode(for: seed, using: symmetricKey)
        let i = Data(authenticationCode)
        let iL = Data(i.prefix(32))
        let iR = Data(i.suffix(32))

        // Verify the key
        // https://github.com/satoshilabs/slips/blob/master/slip-0010.md
        if curve != .ed25519, !(try CryptoUtils.isPrivateKeyValid(iL, curve: curve)) {
            return try makeMasterKey(from: i, curve: curve)
        }

        return ExtendedPrivateKey(privateKey: iL, chainCode: iR, curve: curve)
    }
}

extension BIP32 {
    enum Constants {
        static let hardenedOffset: UInt32 = .init(0x80000000)
        static let hardenedSymbol: String = "'"
        static let alternativeHardenedSymbol: String = "’"
        static let masterKeySymbol: String = "m"
        static let separatorSymbol: Character = "/"
    }

    enum HMACKey: String {
        case secp256k1 = "Bitcoin seed"
        case secp256r1 = "Nist256p1 seed"
        case ed25519 = "ed25519 seed"
    }
}

@available(iOS 13.0, *)
fileprivate extension EllipticCurve {
    var hmacKey: BIP32.HMACKey {
        switch self {
        case .secp256k1:
            return .secp256k1
        case .ed25519:
            return .ed25519
        case .secp256r1:
            return .secp256r1
        case .bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP:
            // https://eips.ethereum.org/EIPS/eip-2333#derive_master_sk
            fatalError("not applicable for this curve")
        }
    }
}
