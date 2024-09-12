//
//  KeysImportTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CryptoKit
@testable import TangemSdk

/// Test that keys uploaded to a card are equal to locally computed. Firmware 6.31
class KeysImportTests: XCTestCase {
    private let entropy = Data(hexString: "6610b25967cdcca9d59875f5cb50b0ea75433311869e930b")
    private let mnemonicString = "gravity machine north sort system female filter attitude volume fold club stay feature office ecology stable narrow fog"
    private let passphrase = "TREZOR"
    private lazy var mnemonic = try! Mnemonic(with: mnemonicString)
    private lazy var seed = try! mnemonic.generateSeed(with: passphrase)

    func testKeyImportSecp256k1() throws {
        let prvKey = try BIP32MasterKeyFactory(seed: seed, curve: .secp256k1).makePrivateKey()
        let pubKey = try prvKey.makePublicKey(for: .secp256k1)

        // validate with WalletCore
        XCTAssertEqual(prvKey.privateKey.hexString, "0BF8F75E9EB03C1FE723DA7E30CAE8D267A9ADF4091DC8140868CBBF16F650DF")

        // validate with card and WalletCore
        XCTAssertEqual(pubKey.publicKey.hexString, "030B0DE47DF425C4BA08D77F927477195FB65E1B238E2366AA1B1BB82E0ACEE1A6")
        XCTAssertEqual(pubKey.chainCode.hexString, "B975E8D7517ED618CBBEBE87555E415874438B670C9E54E57F70FF02A15C4C10")
    }

    @available(iOS 16.0, *)
    func testKeyImportSchnorr() throws {
        let prvKey = try BIP32MasterKeyFactory(seed: seed, curve: .bip0340).makePrivateKey()
        let pubKey = try prvKey.makePublicKey(for: .bip0340)

        // validate with secp256k1
        let publicKeyFromSecp256k1 = try Secp256k1Utils().createXOnlyPublicKey(privateKey: prvKey.privateKey)
        XCTAssertEqual(pubKey.publicKey.hexString, publicKeyFromSecp256k1.hexString)

        // validate with card
        XCTAssertEqual(pubKey.publicKey.hexString, "0B0DE47DF425C4BA08D77F927477195FB65E1B238E2366AA1B1BB82E0ACEE1A6")
        XCTAssertEqual(pubKey.chainCode.hexString, "B975E8D7517ED618CBBEBE87555E415874438B670C9E54E57F70FF02A15C4C10")
    }
    
    @available(iOS 16.0, *)
    func testKeyImportSecp256r1() throws {
        let prvKey = try BIP32MasterKeyFactory(seed: seed, curve: .secp256r1).makePrivateKey()
        let pubKey = (try P256.Signing.PrivateKey(rawRepresentation: prvKey.privateKey)).publicKey.compressedRepresentation

        // validate with WalletCore
        XCTAssertEqual(prvKey.privateKey.hexString, "9ED5DEBE7F5E6430171509A96D68E9966B01AE517D01E49614B1460673788365")

        // validate with card and WalletCore
        XCTAssertEqual(pubKey.hexString, "03D195B795DB30CB1CE7F13F29E1D7E072DA26ED79AB1D0E9F7C999C88A1C800C2")
        XCTAssertEqual(prvKey.chainCode.hexString, "DB214B56C922478EA482F7AF007DB85FDCC8FB1AE03707A21371770EE7D5700F")
    }

    func testKeyImportEd25519Slip0010() throws {
        let prvKey = try BIP32MasterKeyFactory(seed: seed, curve: .ed25519_slip0010).makePrivateKey()
        let pubKey = try prvKey.makePublicKey(for: .ed25519_slip0010)

        // validate with WalletCore
        XCTAssertEqual(prvKey.privateKey.hexString, "0CD28B28383FAF7FDDBE79E34919BCB9FCDA3F505CC3360C2DEADF01C88412FF")
        
        // validate with card and WalletCore
        XCTAssertEqual(pubKey.publicKey.hexString, "335215FCF3105D6A379B8A0372A9E92B42CEED0B2D4E0D7E78E80D16DF41EA6B")
        XCTAssertEqual(pubKey.chainCode.hexString, "837FFAF1B96CA1ACD4A3CB9E08398DC1F21EC657A3BE7679435FC55F9FAE4A46")
    }

    func testKeyImportEd25519() throws {
        /// TrustWallet ignores passphrase https://github.com/trustwallet/wallet-core/blob/master/src/HDWallet.cpp
        let prvKey = try IkarusMasterKeyFactory(entropy: entropy, passphrase: "").makePrivateKey()

        // validate with WalletCore
        XCTAssertEqual(prvKey.privateKey.hexString.lowercased(), "58b41cb27297be1fbf192a65e526179f43b779a383f5d72f14e5db8a82bd77525f65dbfe80724cd61254ec14b351312b63b51c87238ebd3c880a6ad158a161cb")
        XCTAssertEqual(prvKey.chainCode.hexString.lowercased(), "4c3bd3e0df9ea6371678ccf2b741a762825783b8746e2527d8c15749e64b9d60")

        // from TrustWallet's WalletCore
        let pubKey = ExtendedPublicKey(publicKey: Data(hexString: "8d1dbcbe742b3db49533a3ee1166e9b69348fe200a2369443973b826e65b6a61"),
                                       chainCode: Data(hexString: "4c3bd3e0df9ea6371678ccf2b741a762825783b8746e2527d8c15749e64b9d60"))

        // validate with card
        XCTAssertEqual(pubKey.publicKey.hexString, "8D1DBCBE742B3DB49533A3EE1166E9B69348FE200A2369443973B826E65B6A61")
        XCTAssertEqual(pubKey.chainCode.hexString, "4C3BD3E0DF9EA6371678CCF2B741A762825783B8746E2527D8C15749E64B9D60")
    }

    /// All BLS schemes tested to produce same public key.
    func testKeyImportBLS() throws {
        let prvKey = try EIP2333MasterKeyFactory(seed: seed).makePrivateKey()
        //static from code to prevent any changes in future

        // Validated via https://iancoleman.io/eip2333/
        XCTAssertEqual(prvKey.privateKey.hexString, "3492BB55324A0F413798EA71856358556D25AD4EBC9458F062435C7B559E4670")
        XCTAssertEqual(prvKey.chainCode.hexString, "")

        // Validated via:
        // https://iancoleman.io/blsttc_ui/
        // https://github.com/Chia-Network/bls-signatures
        // https://iancoleman.io/eip2333/
        let pubKey = ExtendedPublicKey(publicKey: Data(hexString: "a6d8551cfcf8aefa062c60ffa246466c158e017fba12570327f47a004d5846cf2fabc2952b8f1653f7d224efd9d9b826"), chainCode: Data())

        XCTAssertEqual(pubKey.publicKey.hexString, "A6D8551CFCF8AEFA062C60FFA246466C158E017FBA12570327F47A004D5846CF2FABC2952B8F1653F7D224EFD9D9B826")
        XCTAssertEqual(pubKey.chainCode.hexString, "")

        // proof validated via https://github.com/Chia-Network/bls-signatures
        // A73E200D8FA36522EBBBBD285EFCC9E9F173E9AE7284E42E91FE13D7D7514204E92813AB8082878EAB45867C32EBAA0B106E98FC8DFEB8D3CDA3E1130B8E17AC99BCFC005513F73BB8A17135D78923169BD9567C33C6E9D69D382E018B33FFC1
    }
}
