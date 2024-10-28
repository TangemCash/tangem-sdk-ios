//
//  EllipticCurve.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Elliptic curve used for wallet key operations.
public enum EllipticCurve: String, StringCodable, CaseIterable {
    case secp256k1
    case ed25519
    case ed25519_slip0010
    case secp256r1
    case bls12381_G2
    case bls12381_G2_AUG
    case bls12381_G2_POP
    case bip0340
}

extension EllipticCurve {
    public var supportsDerivation: Bool {
        switch self {
        case .secp256k1, .ed25519, .ed25519_slip0010, .secp256r1, .bip0340:
            return true
        default:
            return false
        }
    }
}
