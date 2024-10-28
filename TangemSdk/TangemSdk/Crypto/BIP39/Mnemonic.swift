//
//  Mnemonic.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 01.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// The `BIP-39` facade
public struct Mnemonic {
    public let mnemonicComponents: [String]
    public let wordlist: BIP39.Wordlist

    public var mnemonic: String { bip39.convertToMnemonicString(mnemonicComponents) }

    private let bip39 = BIP39()

    /// Genarate a mnemonic
    /// - Parameters:
    ///   - entropy: The entropy length to use. Default is 128 bit (12 words).
    ///   - wordList: The Wordlist length to use. Default is en.
    public init(with entropy: EntropyLength = .bits128, wordList: BIP39.Wordlist = .en) throws {
        mnemonicComponents = try bip39.generateMnemonic(entropyLength: entropy, wordlist: wordList)
        self.wordlist = wordList
    }

    /// Parse a mnemonic strind
    /// - Parameter mnemonic: The mnemonic string to use
    public init(with mnemonic: String) throws {
        mnemonicComponents = try bip39.parse(mnemonicString: mnemonic)
        self.wordlist = try bip39.parseWordlist(from: mnemonicComponents)
    }

    /// Generate a seed from the current mnemonic.
    /// - Parameter passphrase: The optional passphrase to use. Empty by defaul.
    /// - Returns: The generated deterministic seed according to BIP-39
    public func generateSeed(with passphrase: String = "") throws -> Data {
        return try bip39.generateSeed(from: mnemonicComponents, passphrase: passphrase)
    }

    /// Returns initial entropy
    /// - Returns: entropy data
    public func getEntropy() throws -> Data {
        return try bip39.getEntropy(from: mnemonicComponents)
    }
}
