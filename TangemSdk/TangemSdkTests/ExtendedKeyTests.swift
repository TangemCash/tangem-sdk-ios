//
//  ExtendedKeyTests.swift.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
@testable import TangemSdk

class ExtendedKeyTests: XCTestCase {
    func testRoundTripPub() throws {
        let key = try ExtendedPublicKey(
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
            chainCode:  Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"),
            depth: 3,
            parentFingerprint: Data(hexString: "0x00000000"),
            childNumber: 2147483648
        )

        let xpubString = try key.serialize(for: .mainnet)
        let deserializedKey = try ExtendedPublicKey(from: xpubString, networkType: .mainnet)

        XCTAssertEqual(key, deserializedKey)
    }

    func testRoundTripPriv() throws {
        let xpriv = "xprv9s21ZrQH143K3Dp5U6YoTum8c6rvMLxbEncwSjfnq12ShNzEhwbCmfvQDPNQTCsEcZJZcLrnf6rt6MCzsMiJYrhLGQwkK1uPCC5QsiAu4tW"
        let key = try ExtendedPrivateKey(from: xpriv, networkType: .mainnet)
        let serialized = try key.serialize(for: .mainnet)
        XCTAssertEqual(xpriv, serialized)
    }

    func testDerived() throws {
        let parentKey = Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2")
        let parentFingerprint = parentKey.sha256Ripemd160.prefix(4)

        let key = ExtendedPublicKey(
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
            chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508")
        )

        let derivedKey = try key.derivePublicKey(node: .nonHardened(2))

        XCTAssertEqual(derivedKey.parentFingerprint, parentFingerprint)
        XCTAssertEqual(derivedKey.depth, 1)
        XCTAssertEqual(derivedKey.childNumber, 2)
    }

    func testInitMaster() throws {
        let key = ExtendedPublicKey(
            publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
            chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508")
        )

        XCTAssertEqual(key.depth, 0)
        XCTAssertEqual(key.parentFingerprint, Data(hexString: "0x00000000"))
        XCTAssertEqual(key.childNumber, 0)
    }

    func testSerializeEdKey() {
        let key = ExtendedPublicKey(publicKey: Data(hexString: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D"),
                                    chainCode: Data(hexString: "02fc9e5af0ac8d9b3cecfe2a888e2117ba3d089d8585886c9c826b6b22a98d12ea"))
        XCTAssertThrowsError(try key.serialize(for: .mainnet))
    }

    func testSerialization() throws {
        let mKeyString = "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
        let mXpubKey = try ExtendedPublicKey(from: mKeyString, networkType: .mainnet)

        let key = try ExtendedPublicKey(
            publicKey: Data(hexString: "035a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56"),
            chainCode: Data(hexString: "47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141"),
            depth: 1,
            parentFingerprint: mXpubKey.publicKey.sha256Ripemd160.prefix(4),
            childNumber: 2147483648
            )

        let serialized = try key.serialize(for: .mainnet)
        XCTAssertEqual(serialized, "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw")
    }

    func testMetaMaskTWCompatible() throws {
        let mnemonicPhrase = "scale wave venue cloth fruit empower afford one domain blouse romance artist"
        let mnemonic = try Mnemonic(with: mnemonicPhrase)
        let seed = try mnemonic.generateSeed()
        XCTAssertEqual(seed.hexString.lowercased(), "d3eea633215dc4cb8ec2acd0d413adec1ebccb597ecf279886e584e9cb9ceb0788eb6f17a585acc12bc58fd586df6bbbdf39af955656f24215cceab174344e62")

        let extendedPrivateKey = try BIP32().makeMasterKey(from: seed, curve: .secp256k1)

        let pk = extendedPrivateKey.privateKey.hexString.lowercased()
        XCTAssertEqual(pk, "589aeb596710f33d7ac31598ec10440a7df8808cf2c3d69ba670ff3fae66aafb")

        XCTAssertEqual(extendedPrivateKey.serializeToWIFCompressed(for: .mainnet), "KzBwvPW6L5iwJSiE5vgS52Y69bUxfwizW3wF4C4Xa3ba3pdd7j63")
    }
}
