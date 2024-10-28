//
//  HKDFTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 26.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import CryptoKit
@testable import TangemSdk

/// https://www.rfc-editor.org/rfc/rfc5869 without SHA1
class HKDFTests: XCTestCase {
    func testCase1() {
        let ikm = Data(hexString: "0x0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b")
        let salt = Data(hexString: "0x000102030405060708090a0b0c")
        let info = Data(hexString: "0xf0f1f2f3f4f5f6f7f8f9")
        let l = 42

        let prk = HKDFUtil<SHA256>.extract(inputKeyMaterial: ikm, salt: salt)
        XCTAssertEqual(prk, Data(hexString: "0x077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5"))
        let okm = HKDFUtil<SHA256>.expand(pseudoRandomKey: prk, info: info, outputByteCount: l)
        XCTAssertEqual(okm, Data(hexString: "0x3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"))
    }


    func testCase2() {
        let ikm = Data(hexString: "0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f")
        let salt = Data(hexString: "0x606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeaf")
        let info = Data(hexString: "0xb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
        let l = 82

        let prk = HKDFUtil<SHA256>.extract(inputKeyMaterial: ikm, salt: salt)
        XCTAssertEqual(prk, Data(hexString: "0x06a6b88c5853361a06104c9ceb35b45cef760014904671014a193f40c15fc244"))
        let okm = HKDFUtil<SHA256>.expand(pseudoRandomKey: prk, info: info, outputByteCount: l)
        XCTAssertEqual(okm.hexString, Data(hexString: "0xb11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87").hexString)
        
    }

    func testCase3() {
        let ikm = Data(hexString: "0x0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b")
        let l = 42

        let prk = HKDFUtil<SHA256>.extract(inputKeyMaterial: ikm)
        XCTAssertEqual(prk, Data(hexString: "0x19ef24a32c717b167f33a91d6f648bdf96596776afdb6377ac434c1c293ccb04"))
        let okm = HKDFUtil<SHA256>.expand(pseudoRandomKey: prk, outputByteCount: l)
        XCTAssertEqual(okm, Data(hexString: "0x8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8"))
    }
}
