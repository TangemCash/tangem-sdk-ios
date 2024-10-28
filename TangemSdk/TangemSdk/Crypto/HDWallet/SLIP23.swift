//
//  SLIP23.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 31.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// https://github.com/satoshilabs/slips/blob/master/slip-0023.md
/// https://github.com/cardano-foundation/CIPs/blob/09d7d8ee1bd64f7e6b20b5a6cae088039dce00cb/CIP-0003/Icarus.md
public struct SLIP23 {
    public init() {}

    /// Generate ikarus master key from mnenonic for ed25519
    /// - Parameter entropy: Initial entropy used to create mnemonic
    /// - Parameter passphrase: Passphrase for mnemonic.  Empty string if not set.
    /// - Returns: `ExtendedPrivateKey`
    public func makeIkarusMasterKey(entropy: Data, passphrase: String) throws -> ExtendedPrivateKey {
        guard let passphraseData = passphrase.data(using: .utf8) else {
            throw SLIP23Error.passphraseToUTF8Failed
        }

        var s = try passphraseData.pbkdf2sha512(salt: entropy, rounds: 4096, keyByteCount: 96)
        s[0] &= 0xF8
        s[31] = (s[31] & 0x1F) | 0x40

        let privateKey = s[0..<64] // kL + kR
        let chainCode = s[64..<96]

        return ExtendedPrivateKey(privateKey: privateKey, chainCode: chainCode)
    }
}

extension SLIP23 {
    enum SLIP23Error: Error {
        case passphraseToUTF8Failed
    }
}
