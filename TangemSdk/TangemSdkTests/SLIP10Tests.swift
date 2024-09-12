//
//  SLIP10Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CryptoKit
@testable import TangemSdk

/// Tests for firmware 6.33
/// test vectors for secp356k1 are equal to BIP32 test vectors
class SLIP10Tests: XCTestCase {
    // MARK: - Test seed retry for nist256p1

    func testSecp256r1MasterKeyGenerationRetry() throws {
        let bip32 = BIP32()
        let masterKey = try bip32.makeMasterKey(from: Data(hexString: "a7305bc8df8d0951f0cb224c0e95d7707cbdf2c6ce7e8d481fec69c7ff5e9446"), curve: .secp256r1)
        XCTAssertEqual(masterKey.privateKey.hexString.lowercased(), "3b8c18469a4634517d6d0b65448f8e6c62091b45540a1743c5846be55d47d88f".lowercased())
        XCTAssertEqual(masterKey.chainCode.hexString.lowercased(), "7762f9729fed06121fd13f326884c82f59aa95c57ac492ce8c9654e60efd130c".lowercased())
    }
}

// MARK: - SLIP10FWTests
class SLIP10FWTests: FWTestCase {
    @available(iOS 16.0, *)
    func testVector1Secp256r1() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256r1: [
            try! DerivationPath(rawPath: "m/0'"),
            try! DerivationPath(rawPath: "m/0'/1"),
            try! DerivationPath(rawPath: "m/0'/1/2'"),
            try! DerivationPath(rawPath: "m/0'/1/2'/2"),
            try! DerivationPath(rawPath: "m/0'/1/2'/2/1000000000"),
        ]]

        let seed = Data(hexString: "000102030405060708090a0b0c0d0e0f")
        let bip32 = BIP32()

        let masterKey = try! bip32.makeMasterKey(from: seed, curve: .secp256r1)
        let masterKeyPublic = (try! P256.Signing.PrivateKey(rawRepresentation: masterKey.privateKey)).publicKey.compressedRepresentation

        printEquals(masterKey.privateKey.hexString.lowercased(), "612091aaa12e22dd2abef664f8a01a82cae99ad7441b7ef8110424915c268bc2")
        printEquals(masterKey.chainCode.hexString.lowercased(), "beeb672fe4621673f722f38529c07392fecaa61015c80c34f29ce8b41b3cb6ea")
        printEquals(masterKeyPublic.hexString.lowercased(), "0266874dc6ade47b3ecd096745ca09bcd29638dd52c2c12117b11ed3e458cfa9e8")

        let iw = CreateWalletTask(curve: .secp256r1, privateKey: masterKey)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                self.printEquals("0266874dc6ade47b3ecd096745ca09bcd29638dd52c2c12117b11ed3e458cfa9e8".uppercased(), wallet.publicKey.hexString)

                // Chain m/0H ext pub
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'")]!
                self.printEquals("0384610f5ecffe8fda089363a41f56a5c7ffc1d81b59a612d0d649b2d22355590c".uppercased(), derived.publicKey.hexString)
                self.printEquals("3460cea53e6a6bb5fb391eeef3237ffd8724bf0a40e94943c98b83825342ee11".uppercased(), derived.chainCode.hexString)

                // Chain m/0H/1 ext pub
                let derived1 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1")]!
                self.printEquals("03526c63f8d0b4bbbf9c80df553fe66742df4676b241dabefdef67733e070f6844".uppercased(), derived1.publicKey.hexString)
                self.printEquals("4187afff1aafa8445010097fb99d23aee9f599450c7bd140b6826ac22ba21d0c".uppercased(), derived1.chainCode.hexString)

                // Chain m/0H/1/2H ext pub
                let derived2 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1/2'")]!
                self.printEquals("0359cf160040778a4b14c5f4d7b76e327ccc8c4a6086dd9451b7482b5a4972dda0".uppercased(), derived2.publicKey.hexString)
                self.printEquals("98c7514f562e64e74170cc3cf304ee1ce54d6b6da4f880f313e8204c2a185318".uppercased(), derived2.chainCode.hexString)

                // Chain m/0H/1/2H/2 ext pub
                let derived3 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1/2'/2")]!
                self.printEquals("029f871f4cb9e1c97f9f4de9ccd0d4a2f2a171110c61178f84430062230833ff20".uppercased(), derived3.publicKey.hexString)
                self.printEquals("ba96f776a5c3907d7fd48bde5620ee374d4acfd540378476019eab70790c63a0".uppercased(), derived3.chainCode.hexString)

                // Chain m/0H/1/2H/2/1000000000 ext pub
                let derived4 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1/2'/2/1000000000")]!
                self.printEquals("02216cd26d31147f72427a453c443ed2cde8a1e53c9cc44e5ddf739725413fe3f4".uppercased(), derived4.publicKey.hexString)
                self.printEquals("b9b7b82d326bb9cb5b5b121066feea4eb93d5241103c9e7a18aad40f1dde8059".uppercased(), derived4.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }

    @available(iOS 16.0, *)
    func testVector2Secp256r1() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256r1: [
            try! DerivationPath(rawPath: "m/0"),
            try! DerivationPath(rawPath: "m/0/2147483647'"),
            try! DerivationPath(rawPath: "m/0/2147483647'/1"),
            try! DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'"),
            try! DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'/2"),
        ]]

        let seed = Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
        let bip32 = BIP32()

        let masterKey = try! bip32.makeMasterKey(from: seed, curve: .secp256r1)
        let masterKeyPublic = (try! P256.Signing.PrivateKey(rawRepresentation: masterKey.privateKey)).publicKey.compressedRepresentation

        printEquals(masterKey.privateKey.hexString.lowercased(), "eaa31c2e46ca2962227cf21d73a7ef0ce8b31c756897521eb6c7b39796633357")
        printEquals(masterKey.chainCode.hexString.lowercased(), "96cd4465a9644e31528eda3592aa35eb39a9527769ce1855beafc1b81055e75d")
        printEquals(masterKeyPublic.hexString.lowercased(), "02c9e16154474b3ed5b38218bb0463e008f89ee03e62d22fdcc8014beab25b48fa")

        let iw = CreateWalletTask(curve: .secp256r1, privateKey: masterKey)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                self.printEquals("02c9e16154474b3ed5b38218bb0463e008f89ee03e62d22fdcc8014beab25b48fa".uppercased(), wallet.publicKey.hexString)

                // Chain m/0 ext pub
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'")]!
                self.printEquals("039b6df4bece7b6c81e2adfeea4bcf5c8c8a6e40ea7ffa3cf6e8494c61a1fc82cc".uppercased(), derived.publicKey.hexString)
                self.printEquals("84e9c258bb8557a40e0d041115b376dd55eda99c0042ce29e81ebe4efed9b86a".uppercased(), derived.chainCode.hexString)

                // Chain m/0/2147483647H ext pub
                let derived1 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0/2147483647'")]!
                self.printEquals("02f89c5deb1cae4fedc9905f98ae6cbf6cbab120d8cb85d5bd9a91a72f4c068c76".uppercased(), derived1.publicKey.hexString)
                self.printEquals("f235b2bc5c04606ca9c30027a84f353acf4e4683edbd11f635d0dcc1cd106ea6".uppercased(), derived1.chainCode.hexString)

                // Chain m/0/2147483647H/1 ext pub
                let derived2 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0/2147483647'/1")]!
                self.printEquals("03abe0ad54c97c1d654c1852dfdc32d6d3e487e75fa16f0fd6304b9ceae4220c64".uppercased(), derived2.publicKey.hexString)
                self.printEquals("7c0b833106235e452eba79d2bdd58d4086e663bc8cc55e9773d2b5eeda313f3b".uppercased(), derived2.chainCode.hexString)

                // Chain m/0/2147483647H/1/2147483646H ext pub
                let derived3 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'")]!
                self.printEquals("03cb8cb067d248691808cd6b5a5a06b48e34ebac4d965cba33e6dc46fe13d9b933".uppercased(), derived3.publicKey.hexString)
                self.printEquals("5794e616eadaf33413aa309318a26ee0fd5163b70466de7a4512fd4b1a5c9e6a".uppercased(), derived3.chainCode.hexString)

                // Chain m/0/2147483647'/1/2147483646'/2 ext pub
                let derived4 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1/2'/2/1000000000")]!
                self.printEquals("020ee02e18967237cf62672983b253ee62fa4dd431f8243bfeccdf39dbe181387f".uppercased(), derived4.publicKey.hexString)
                self.printEquals("3bfb29ee8ac4484f09db09c2079b520ea5616df7820f071a20320366fbe226a7".uppercased(), derived4.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }

    // MARK: - Test derivation retry for nist256p1

    func testSecp256r1DerivationRetry() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [ .secp256r1: [try! DerivationPath(rawPath: "m/28578'"),
                                                           try! DerivationPath(rawPath: "m/28578'/33941")]]
        let bip32 = BIP32()
        let masterKey = try! bip32.makeMasterKey(from: Data(hexString: "000102030405060708090a0b0c0d0e0f"), curve: .secp256r1)

        printEquals(masterKey.privateKey.hexString.lowercased(), "612091aaa12e22dd2abef664f8a01a82cae99ad7441b7ef8110424915c268bc2".lowercased())
        printEquals(masterKey.chainCode.hexString.lowercased(), "beeb672fe4621673f722f38529c07392fecaa61015c80c34f29ce8b41b3cb6ea".lowercased())


        let iw = CreateWalletTask(curve: .secp256r1, privateKey: masterKey)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                self.printEquals("0266874dc6ade47b3ecd096745ca09bcd29638dd52c2c12117b11ed3e458cfa9e8".uppercased(), wallet.publicKey.hexString)

                // Chain m/28578H
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/28578'")]!
                self.printEquals("02519b5554a4872e8c9c1c847115363051ec43e93400e030ba3c36b52a3e70a5b7".uppercased(), derived.publicKey.hexString)
                self.printEquals("e94c8ebe30c2250a14713212f6449b20f3329105ea15b652ca5bdfc68f6c65c2".uppercased(), derived.chainCode.hexString)

                // Chain m/28578H/33941
                let derived1 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/28578'/33941")]!
                self.printEquals("0235bfee614c0d5b2cae260000bb1d0d84b270099ad790022c1ae0b2e782efe120".uppercased(), derived1.publicKey.hexString)
                self.printEquals("9e87fe95031f14736774cd82f25fd885065cb7c358c1edf813c72af535e83071".uppercased(), derived1.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }

    func testVector1Ed5519Slip0010() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.ed25519_slip0010: [
            try! DerivationPath(rawPath: "m/0'"),
            try! DerivationPath(rawPath: "m/0'/1'"),
            try! DerivationPath(rawPath: "m/0'/1'/2'"),
            try! DerivationPath(rawPath: "m/0'/1'/2'/2'"),
            try! DerivationPath(rawPath: "m/0'/1'/2'/2'/1000000000'"),
        ]]

        let seed = Data(hexString: "000102030405060708090a0b0c0d0e0f")
        let bip32 = BIP32()

        let masterKey = try! bip32.makeMasterKey(from: seed, curve: .ed25519_slip0010)

        printEquals(masterKey.privateKey.hexString, "2b4be7f19ee27bbf30c667b642d5f4aa69fd169872f8fc3059c08ebae2eb19e7".uppercased())
        printEquals(masterKey.chainCode.hexString, "90046a93de5380a72b5e45010748567d5ea02bbf6522f979e05c0d8d8ca9fffb".uppercased())
        printEquals(try! masterKey.makePublicKey(for: .ed25519_slip0010).publicKey.hexString, "00a4b2856bfec510abab89753fac1ac0e1112364e7d250545963f135f2a33188ed".dropFirst(2).uppercased())

        let iw = CreateWalletTask(curve: .ed25519_slip0010, privateKey: masterKey)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                self.printEquals("00a4b2856bfec510abab89753fac1ac0e1112364e7d250545963f135f2a33188ed".dropFirst(2).uppercased(), wallet.publicKey.hexString)

                // Chain m/0H ext pub
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'")]!
                self.printEquals("008c8a13df77a28f3445213a0f432fde644acaa215fc72dcdf300d5efaa85d350c".dropFirst(2).uppercased(), derived.publicKey.hexString)
                self.printEquals("8b59aa11380b624e81507a27fedda59fea6d0b779a778918a2fd3590e16e9c69".uppercased(), derived.chainCode.hexString)

                // Chain m/0H/1 ext pub
                let derived1 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1'")]!
                self.printEquals("001932a5270f335bed617d5b935c80aedb1a35bd9fc1e31acafd5372c30f5c1187".dropFirst(2).uppercased(), derived1.publicKey.hexString)
                self.printEquals("a320425f77d1b5c2505a6b1b27382b37368ee640e3557c315416801243552f14".uppercased(), derived1.chainCode.hexString)

                // Chain m/0H/1/2H ext pub
                let derived2 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1'/2'")]!
                self.printEquals("00ae98736566d30ed0e9d2f4486a64bc95740d89c7db33f52121f8ea8f76ff0fc1".dropFirst(2).uppercased(), derived2.publicKey.hexString)
                self.printEquals("2e69929e00b5ab250f49c3fb1c12f252de4fed2c1db88387094a0f8c4c9ccd6c".uppercased(), derived2.chainCode.hexString)

                // Chain m/0H/1/2H/2 ext pub
                let derived3 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1'/2'/2'")]!
                self.printEquals("008abae2d66361c879b900d204ad2cc4984fa2aa344dd7ddc46007329ac76c429c".dropFirst(2).uppercased(), derived3.publicKey.hexString)
                self.printEquals("8f6d87f93d750e0efccda017d662a1b31a266e4a6f5993b15f5c1f07f74dd5cc".uppercased(), derived3.chainCode.hexString)

                // Chain m/0H/1/2H/2/1000000000 ext pub
                let derived4 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1'/2'/2'/1000000000'")]!
                self.printEquals("003c24da049451555d51a7014a37337aa4e12d41e485abccfa46b47dfb2af54b7a".dropFirst(2).uppercased(), derived4.publicKey.hexString)
                self.printEquals("68789923a0cac2cd5a29172a475fe9e0fb14cd6adb5ad98a3fa70333e7afa230".uppercased(), derived4.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }

    func testVector2Ed5519Slip0010() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.ed25519_slip0010: [
            try! DerivationPath(rawPath: "m/0'"),
            try! DerivationPath(rawPath: "m/0'/2147483647'"),
            try! DerivationPath(rawPath: "m/0'/2147483647'/1'"),
            try! DerivationPath(rawPath: "m/0'/2147483647'/1'/2147483646'"),
            try! DerivationPath(rawPath: "m/0'/2147483647'/1'/2147483646'/2'"),
        ]]

        let seed = Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
        let bip32 = BIP32()

        let masterKey = try! bip32.makeMasterKey(from: seed, curve: .ed25519_slip0010)

        printEquals(masterKey.privateKey.hexString, "171cb88b1b3c1db25add599712e36245d75bc65a1a5c9e18d76f9f2b1eab4012".uppercased())
        printEquals(masterKey.chainCode.hexString, "ef70a74db9c3a5af931b5fe73ed8e1a53464133654fd55e7a66f8570b8e33c3b".uppercased())
        printEquals(try! masterKey.makePublicKey(for: .ed25519_slip0010).publicKey.hexString, "008fe9693f8fa62a4305a140b9764c5ee01e455963744fe18204b4fb948249308a".dropFirst(2).uppercased())

        let iw = CreateWalletTask(curve: .ed25519_slip0010, privateKey: masterKey)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                self.printEquals("008fe9693f8fa62a4305a140b9764c5ee01e455963744fe18204b4fb948249308a".dropFirst(2).uppercased(), wallet.publicKey.hexString)

                // Chain m/0H ext pub
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'")]!
                self.printEquals("0086fab68dcb57aa196c77c5f264f215a112c22a912c10d123b0d03c3c28ef1037".dropFirst(2).uppercased(), derived.publicKey.hexString)
                self.printEquals("0b78a3226f915c082bf118f83618a618ab6dec793752624cbeb622acb562862d".uppercased(), derived.chainCode.hexString)

                // Chain m/0H/2147483647H ext pub
                let derived1 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/2147483647'")]!
                self.printEquals("005ba3b9ac6e90e83effcd25ac4e58a1365a9e35a3d3ae5eb07b9e4d90bcf7506d".dropFirst(2).uppercased(), derived1.publicKey.hexString)
                self.printEquals("138f0b2551bcafeca6ff2aa88ba8ed0ed8de070841f0c4ef0165df8181eaad7f".uppercased(), derived1.chainCode.hexString)

                // Chain m/0H/2147483647H/1H ext pub
                let derived2 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/2147483647'/1'")]!
                self.printEquals("002e66aa57069c86cc18249aecf5cb5a9cebbfd6fadeab056254763874a9352b45".dropFirst(2).uppercased(), derived2.publicKey.hexString)
                self.printEquals("73bd9fff1cfbde33a1b846c27085f711c0fe2d66fd32e139d3ebc28e5a4a6b90".uppercased(), derived2.chainCode.hexString)

                // Chain m/0H/2147483647H/1H/2147483646H ext pub
                let derived3 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/2147483647'/1'/2147483646'")]!
                self.printEquals("00e33c0f7d81d843c572275f287498e8d408654fdf0d1e065b84e2e6f157aab09b".dropFirst(2).uppercased(), derived3.publicKey.hexString)
                self.printEquals("0902fe8a29f9140480a00ef244bd183e8a13288e4412d8389d140aac1794825a".uppercased(), derived3.chainCode.hexString)

                // Chain m/0H/2147483647H/1H/2147483646H/2H ext pub
                let derived4 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/2147483647'/1'/2147483646'/2'")]!
                self.printEquals("0047150c75db263559a70d5778bf36abbab30fb061ad69f69ece61a72b0cfa4fc0".dropFirst(2).uppercased(), derived4.publicKey.hexString)
                self.printEquals("5d70af781f3a37b829f0d060924d5e960bdc02e85423494afc0b1a41bbe196d4".uppercased(), derived4.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }
}
