//
//  BIP39Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 06.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class BIP39Tests: XCTestCase {
    func testReadWords() {
        let langs = BIP39.Wordlist.allCases

        for lang in langs {
            XCTAssertTrue(lang.words.count == 2048)
        }
    }

    func testMnemonicGenerationBase() throws  {
        let entropyLengthArray = EntropyLength.allCases
        let wordLists = BIP39.Wordlist.allCases

        let bip39 = BIP39()

        for entropyLength in entropyLengthArray {
            for wordlist in wordLists {
                let mnemonic = try bip39.generateMnemonic(entropyLength: entropyLength, wordlist: wordlist)
                XCTAssertEqual(mnemonic.count, entropyLength.wordCount)
            }
        }
    }

    func testMnemonicByEnVectors() throws  {
        guard let allVectors = try getTestVectors(from: Constants.seedTestVectorsFilename),
              let vectors = allVectors[Constants.englishTestVectors] as? [[String]] else {
            XCTFail("Failed to parse test vectors file.")
            return
        }

        let bip39 = BIP39()
        
        for vector in vectors {
            let entropy = vector[0]
            let expectedMnemonic = vector[1]
            let expectedSeed = vector[2]
            let expectedExtendedKey = vector[3]

            let mnemonic = try bip39.generateMnemonic(from: Data(hexString: entropy), wordlist: .en)
            let mnemonicString = bip39.convertToMnemonicString(mnemonic)
            XCTAssertEqual(mnemonicString, expectedMnemonic)

            let calculatedEntropy = try bip39.getEntropy(from: mnemonic)
            XCTAssertEqual(calculatedEntropy.hexString.lowercased(), entropy)

            let seed = try bip39.generateSeed(from: mnemonic, passphrase: Constants.passphrase)
            XCTAssertEqual(seed.hexString.lowercased(), expectedSeed)

            let key = try BIP32().makeMasterKey(from: seed, curve: .secp256k1)
            let extendedKey = try key.serialize(for: .mainnet)
            XCTAssertEqual(extendedKey, expectedExtendedKey)
        }
    }

    func testParseMnemonic() throws {
        guard let allVectors = try getTestVectors(from: Constants.mnemonicValidTestVectorsFilename),
              let vectors = allVectors[Constants.englishTestVectors] as? [[String]] else {
            XCTFail("Failed to parse test vectors file.")
            return
        }

        let bip39 = BIP39()

        for vector in vectors {
            let mnemonicToParse = vector[0]
            let expectedMnemonic = vector[1]

            let parsedMnemonic = try bip39.parse(mnemonicString: mnemonicToParse)
            let parsedMnemonicString = bip39.convertToMnemonicString(parsedMnemonic)
            XCTAssertEqual(parsedMnemonicString, expectedMnemonic)
        }
    }

    func testParseInvalidMnemonic() throws {
        guard let allVectors = try getTestVectors(from: Constants.mnemonicInvalidTestVectorsFilename),
              let vectors = allVectors[Constants.englishTestVectors] as? [[String]],
              let firstVector = vectors.first else {
            XCTFail("Failed to parse test vectors file.")
            return
        }

        let bip39 = BIP39()

        for cases in firstVector {
            XCTAssertThrowsError(try bip39.parse(mnemonicString: cases))
        }
    }

    func testSwapWords() throws {
        let bip39 = BIP39()
        let valid = "legal winner thank year wave sausage worth useful legal winner thank yellow"
        XCTAssertNoThrow(try bip39.parse(mnemonicString: valid))

        var components = valid.split(separator: " ")
        components.swapAt(3, 4)
        let invalid = components.joined(separator: " ")
        XCTAssertThrowsError(try bip39.parse(mnemonicString: invalid))
    }

    private func getTestVectors(from filename: String) throws -> [String: Any]? {
        let data = try Bundle.readFileAsData(name: filename, in: .bip39)

        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }

        return dictionary
    }
}

private extension BIP39Tests {
    enum Constants {
        static let englishTestVectors = "english"
        static let passphrase = "TREZOR"
        static let seedTestVectorsFilename = "seed_test_vectors"
        static let mnemonicValidTestVectorsFilename = "mnemonic_valid_test_vectors"
        static let mnemonicInvalidTestVectorsFilename = "mnemonic_invalid_test_vectors"
    }
}
