//
//  BIP32Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 07.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CryptoKit
@testable import TangemSdk

/// Tests for firmware 6.33
/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
class BIP32Tests: XCTestCase {
    // MARK: - Test vector 5

    // https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#user-content-Test_Vectors
    func testVector5() {
        // (invalid pubkey 020000000000000000000000000000000000000000000000000000000000000007)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6Q5JXayek4PRsn35jii4veMimro1xefsM58PgBMrvdYre8QyULY", networkType: .mainnet))

        // (unknown extended key version)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "DMwo58pR1QLEFihHiXPVykYB6fJmsTeHvyTp7hRThAtCX8CvYzgPcn8XnmdfHPmHJiEDXkTiJTVV9rHEBUem2mwVbbNfvT2MTcAqj3nesx8uBf9", networkType:.mainnet))

        // (unknown extended key version)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "DMwo58pR1QLEFihHiXPVykYB6fJmsTeHvyTp7hRThAtCX8CvYzgPcn8XnmdfHGMQzT7ayAmfo4z3gY5KfbrZWZ6St24UVf2Qgo6oujFktLHdHY4", networkType:.mainnet))

        // (zero depth with non-zero index)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAuDcm6CRQ5N4qiHKrJ39Xe1R1NyfouMKTTWcguwVcfrZJaNvhpebzGerh7gucBvzEQWRugZDuDXjNDRmXzSZe4c7mnTK97pTvGS8", networkType: .mainnet))

        // (zero depth with non-zero parent fingerprint)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661no6RGEX3uJkY4bNnPcw4URcQTrSibUZ4NqJEw5eBkv7ovTwgiT91XX27VbEXGENhYRCf7hyEbWrR3FewATdCEebj6znwMfQkhRYHRLpJ", networkType: .mainnet))

        // (pubkey version / prvkey mismatch)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6LBpB85b3D2yc8sfvZU521AAwdZafEz7mnzBBsz4wKY5fTtTQBm", networkType: .mainnet))

        // (prvkey version / pubkey mismatch)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFGTQQD3dC4H2D5GBj7vWvSQaaBv5cxi9gafk7NF3pnBju6dwKvH", networkType: .mainnet))

        // (invalid pubkey prefix 04)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6Txnt3siSujt9RCVYsx4qHZGc62TG4McvMGcAUjeuwZdduYEvFn", networkType: .mainnet))

        // (invalid prvkey prefix 04)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFGpWnsj83BHtEy5Zt8CcDr1UiRXuWCmTQLxEK9vbz5gPstX92JQ", networkType: .mainnet))

        // (invalid pubkey prefix 01)
        XCTAssertThrowsError(try ExtendedPublicKey(from: "xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3zgtU6N8ZMMXctdiCjxTNq964yKkwrkBJJwpzZS4HS2fxvyYUA4q2Xe4", networkType: .mainnet))

        // (invalid prvkey prefix 01)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFAzHGBP2UuGCqWLTAPLcMtD9y5gkZ6Eq3Rjuahrv17fEQ3Qen6J", networkType: .mainnet))

        // (zero depth with non-zero parent fingerprint)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s2SPatNQ9Vc6GTbVMFPFo7jsaZySyzk7L8n2uqKXJen3KUmvQNTuLh3fhZMBoG3G4ZW1N2kZuHEPY53qmbZzCHshoQnNf4GvELZfqTUrcv", networkType: .mainnet))

        // (zero depth with non-zero index)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH4r4TsiLvyLXqM9P7k1K3EYhA1kkD6xuquB5i39AU8KF42acDyL3qsDbU9NmZn6MsGSUYZEsuoePmjzsB3eFKSUEh3Gu1N3cqVUN", networkType: .mainnet))

        // (private key 0 not in 1..n-1)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzF93Y5wvzdUayhgkkFoicQZcP3y52uPPxFnfoLZB21Teqt1VvEHx", networkType: .mainnet))

        // (private key n not in 1..n-1)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63oStZzFAzHGBP2UuGCqWLTAPLcMtD5SDKr24z3aiUvKr9bJpdrcLg1y3G", networkType: .mainnet))

        // (invalid checksum)
        XCTAssertThrowsError(try ExtendedPrivateKey(from: "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHL", networkType: .mainnet))
    }
}


// MARK: - SLIP10FWTests

class BIP32FWTests: FWTestCase {
    func testVector1() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256k1: [
            try! DerivationPath(rawPath: "m/0'"),
            try! DerivationPath(rawPath: "m/0'/1"),
            try! DerivationPath(rawPath: "m/0'/1/2'"),
            try! DerivationPath(rawPath: "m/0'/1/2'/2"),
            try! DerivationPath(rawPath: "m/0'/1/2'/2/1000000000"),
        ]]

        let seed = Data(hexString: "000102030405060708090a0b0c0d0e0f")
        let bip32 = BIP32()

        let mPrv = try! bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try! mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try! mPrv.serialize(for: .mainnet)
        printEquals(xPrv, "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi")

        let xPub = try! mPub.serialize(for: .mainnet)
        printEquals(xPub, "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8")

        let iw = CreateWalletTask(curve: .secp256k1, privateKey: mPrv)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                let expectedM = try! ExtendedPublicKey(from: "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8", networkType: .mainnet)
                self.printEquals(expectedM.publicKey.hexString, wallet.publicKey.hexString)
                self.printEquals(expectedM.chainCode.hexString, wallet.chainCode!.hexString)

                // Chain m/0H ext pub
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'")]!
                let expected = try! ExtendedPublicKey(from: "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw", networkType: .mainnet)
                self.printEquals(expected.publicKey.hexString, derived.publicKey.hexString)
                self.printEquals(expected.chainCode.hexString, derived.chainCode.hexString)

                // Chain m/0H/1 ext pub
                let derived1 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1")]!
                let expected1 = try! ExtendedPublicKey(from: "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ", networkType: .mainnet)
                self.printEquals(expected1.publicKey.hexString, derived1.publicKey.hexString)
                self.printEquals(expected1.chainCode.hexString, derived1.chainCode.hexString)

                // Chain m/0H/1/2H ext pub
                let derived2 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1/2'")]!
                let expected2 = try! ExtendedPublicKey(from: "xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5", networkType: .mainnet)
                self.printEquals(expected2.publicKey.hexString, derived2.publicKey.hexString)
                self.printEquals(expected2.chainCode.hexString, derived2.chainCode.hexString)

                // Chain m/0H/1/2H/2 ext pub
                let derived3 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1/2'/2")]!
                let expected3 = try! ExtendedPublicKey(from: "xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV", networkType: .mainnet)
                self.printEquals(expected3.publicKey.hexString, derived3.publicKey.hexString)
                self.printEquals(expected3.chainCode.hexString, derived3.chainCode.hexString)

                // Chain m/0H/1/2H/2/1000000000 ext pub
                let derived4 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1/2'/2/1000000000")]!
                let expected4 = try! ExtendedPublicKey(from: "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy", networkType: .mainnet)
                self.printEquals(expected4.publicKey.hexString, derived4.publicKey.hexString)
                self.printEquals(expected4.chainCode.hexString, derived4.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }
    func testVector2() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256k1: [
            try! DerivationPath(rawPath: "m/0"),
            try! DerivationPath(rawPath: "m/0/2147483647'"),
            try! DerivationPath(rawPath: "m/0/2147483647'/1"),
            try! DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'"),
            try! DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'/2"),
        ]]

        let seed = Data(hexString: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542")
        let bip32 = BIP32()

        let mPrv = try! bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try! mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try! mPrv.serialize(for: .mainnet)
        printEquals(xPrv, "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U")

        let xPub = try! mPub.serialize(for: .mainnet)
        printEquals(xPub, "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB")

        let iw = CreateWalletTask(curve: .secp256k1, privateKey: mPrv)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                let expectedM = try! ExtendedPublicKey(from: "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB", networkType: .mainnet)
                self.printEquals(expectedM.publicKey.hexString, wallet.publicKey.hexString)
                self.printEquals(expectedM.chainCode.hexString, wallet.chainCode!.hexString)

                // Chain m/0 ext pub
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0")]!
                let expected = try! ExtendedPublicKey(from: "xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH", networkType: .mainnet)
                self.printEquals(expected.publicKey.hexString, derived.publicKey.hexString)
                self.printEquals(expected.chainCode.hexString, derived.chainCode.hexString)

                // Chain m/0/2147483647H ext pub
                let derived1 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0/2147483647'")]!
                let expected1 = try! ExtendedPublicKey(from: "xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a", networkType: .mainnet)
                self.printEquals(expected1.publicKey.hexString, derived1.publicKey.hexString)
                self.printEquals(expected1.chainCode.hexString, derived1.chainCode.hexString)

                // Chain m/0/2147483647H/1 ext pub
                let derived2 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0/2147483647'/1")]!
                let expected2 = try! ExtendedPublicKey(from: "xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon", networkType: .mainnet)
                self.printEquals(expected2.publicKey.hexString, derived2.publicKey.hexString)
                self.printEquals(expected2.chainCode.hexString, derived2.chainCode.hexString)

                // Chain m/0/2147483647H/1/2147483646H  ext pub
                let derived3 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'")]!
                let expected3 = try! ExtendedPublicKey(from: "xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL", networkType: .mainnet)
                self.printEquals(expected3.publicKey.hexString, derived3.publicKey.hexString)
                self.printEquals(expected3.chainCode.hexString, derived3.chainCode.hexString)

                /// Chain m/0/2147483647H/1/2147483646H/2 ext pub
                let derived4 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0/2147483647'/1/2147483646'/2")]!
                let expected4 = try! ExtendedPublicKey(from: "xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt", networkType: .mainnet)
                self.printEquals(expected4.publicKey.hexString, derived4.publicKey.hexString)
                self.printEquals(expected4.chainCode.hexString, derived4.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }

    func testVector3() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256k1: [
            try! DerivationPath(rawPath: "m/0'"),
        ]]

        let seed = Data(hexString: "4b381541583be4423346c643850da4b320e46a87ae3d2a4e6da11eba819cd4acba45d239319ac14f863b8d5ab5a0d0c64d2e8a1e7d1457df2e5a3c51c73235be")
        let bip32 = BIP32()

        let mPrv = try! bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try! mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try! mPrv.serialize(for: .mainnet)
        printEquals(xPrv, "xprv9s21ZrQH143K25QhxbucbDDuQ4naNntJRi4KUfWT7xo4EKsHt2QJDu7KXp1A3u7Bi1j8ph3EGsZ9Xvz9dGuVrtHHs7pXeTzjuxBrCmmhgC6")

        let xPub = try! mPub.serialize(for: .mainnet)
        printEquals(xPub, "xpub661MyMwAqRbcEZVB4dScxMAdx6d4nFc9nvyvH3v4gJL378CSRZiYmhRoP7mBy6gSPSCYk6SzXPTf3ND1cZAceL7SfJ1Z3GC8vBgp2epUt13")

        let iw = CreateWalletTask(curve: .secp256k1, privateKey: mPrv)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                let expectedM = try! ExtendedPublicKey(from: "xpub661MyMwAqRbcEZVB4dScxMAdx6d4nFc9nvyvH3v4gJL378CSRZiYmhRoP7mBy6gSPSCYk6SzXPTf3ND1cZAceL7SfJ1Z3GC8vBgp2epUt13", networkType: .mainnet)
                self.printEquals(expectedM.publicKey.hexString, wallet.publicKey.hexString)
                self.printEquals(expectedM.chainCode.hexString, wallet.chainCode!.hexString)

                // Chain m/0' ext pub
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'")]!
                let expected = try! ExtendedPublicKey(from: "xpub68NZiKmJWnxxS6aaHmn81bvJeTESw724CRDs6HbuccFQN9Ku14VQrADWgqbhhTHBaohPX4CjNLf9fq9MYo6oDaPPLPxSb7gwQN3ih19Zm4Y", networkType: .mainnet)
                self.printEquals(expected.publicKey.hexString, derived.publicKey.hexString)
                self.printEquals(expected.chainCode.hexString, derived.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }

    func testVector4() {
        let sdk = TangemSdk()
        sdk.config.defaultDerivationPaths = [.secp256k1: [
            try! DerivationPath(rawPath: "m/0'"),
            try! DerivationPath(rawPath: "m/0'/1'"),
        ]]

        let seed = Data(hexString: "3ddd5602285899a946114506157c7997e5444528f3003f6134712147db19b678")
        let bip32 = BIP32()

        let mPrv = try! bip32.makeMasterKey(from: seed, curve: .secp256k1)
        let mPub = try! mPrv.makePublicKey(for: .secp256k1)

        let xPrv = try! mPrv.serialize(for: .mainnet)
        printEquals(xPrv, "xprv9s21ZrQH143K48vGoLGRPxgo2JNkJ3J3fqkirQC2zVdk5Dgd5w14S7fRDyHH4dWNHUgkvsvNDCkvAwcSHNAQwhwgNMgZhLtQC63zxwhQmRv")

        let xPub = try! mPub.serialize(for: .mainnet)
        printEquals(xPub, "xpub661MyMwAqRbcGczjuMoRm6dXaLDEhW1u34gKenbeYqAix21mdUKJyuyu5F1rzYGVxyL6tmgBUAEPrEz92mBXjByMRiJdba9wpnN37RLLAXa")

        let iw = CreateWalletTask(curve: .secp256k1, privateKey: mPrv)

        sdk.startSession(with: iw) { result in
            switch result {
            case .success(let response):
                let wallet = response.wallet

                // Chain m
                let expectedM = try! ExtendedPublicKey(from: "xpub661MyMwAqRbcGczjuMoRm6dXaLDEhW1u34gKenbeYqAix21mdUKJyuyu5F1rzYGVxyL6tmgBUAEPrEz92mBXjByMRiJdba9wpnN37RLLAXa", networkType: .mainnet)
                self.printEquals(expectedM.publicKey.hexString, wallet.publicKey.hexString)
                self.printEquals(expectedM.chainCode.hexString, wallet.chainCode!.hexString)

                // Chain m/0' ext pub
                let derived = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'")]!
                let expected = try! ExtendedPublicKey(from: "xpub69AUMk3qDBi3uW1sXgjCmVjJ2G6WQoYSnNHyzkmdCHEhSZ4tBok37xfFEqHd2AddP56Tqp4o56AePAgCjYdvpW2PU2jbUPFKsav5ut6Ch1m", networkType: .mainnet)
                self.printEquals(expected.publicKey.hexString, derived.publicKey.hexString)
                self.printEquals(expected.chainCode.hexString, derived.chainCode.hexString)

                // Chain m/0H/1H ext pub
                let derived1 = wallet.derivedKeys[try! DerivationPath(rawPath: "m/0'/1'")]!
                let expected1 = try! ExtendedPublicKey(from: "xpub6BJA1jSqiukeaesWfxe6sNK9CCGaujFFSJLomWHprUL9DePQ4JDkM5d88n49sMGJxrhpjazuXYWdMf17C9T5XnxkopaeS7jGk1GyyVziaMt", networkType: .mainnet)
                self.printEquals(expected1.publicKey.hexString, derived1.publicKey.hexString)
                self.printEquals(expected1.chainCode.hexString, derived1.chainCode.hexString)

            case .failure(let error):
                print(error)
            }

            withExtendedLifetime(sdk, {})
        }
    }
}
