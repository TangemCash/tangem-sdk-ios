//
//  BIP32MasterKeyFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 31.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BIP32MasterKeyFactory: MasterKeyFactory {
    private let seed: Data
    private let curve: EllipticCurve

    init(seed: Data, curve: EllipticCurve) {
        self.seed = seed
        self.curve = curve
    }

    func makePrivateKey() throws -> ExtendedPrivateKey {
        return try BIP32().makeMasterKey(from: seed, curve: curve)
    }
}
