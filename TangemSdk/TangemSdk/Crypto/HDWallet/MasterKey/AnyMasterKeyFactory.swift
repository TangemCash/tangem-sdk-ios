//
//  AnyMasterKeyFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 31.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct AnyMasterKeyFactory {
    private let mnemonic: Mnemonic
    private let passphrase: String

    public init(mnemonic: Mnemonic, passphrase: String) {
        self.mnemonic = mnemonic
        self.passphrase = passphrase
    }
    
    public func makeMasterKey(for curve: EllipticCurve) throws -> ExtendedPrivateKey {
        let factory = try makeFactory(for: curve)
        return try factory.makePrivateKey()
    }

    private func makeFactory(for curve: EllipticCurve) throws -> MasterKeyFactory {
        switch curve {
        case .bip0340, .ed25519_slip0010, .secp256k1, .secp256r1:
            return BIP32MasterKeyFactory(seed: try getSeed(), curve: curve)
        case .bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP:
            return EIP2333MasterKeyFactory(seed: try getSeed())
        case .ed25519:
            return IkarusMasterKeyFactory(entropy: try mnemonic.getEntropy(), passphrase: passphrase)
        }
    }

    private func getSeed() throws -> Data {
        return try mnemonic.generateSeed(with: passphrase)
    }
}
