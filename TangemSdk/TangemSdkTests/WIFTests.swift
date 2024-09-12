//
//  WIFTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
@testable import TangemSdk

class WIFTests: XCTestCase {
    func testRoundTrip() {
        let key = Data(hexString: "589aeb596710f33d7ac31598ec10440a7df8808cf2c3d69ba670ff3fae66aafb")
        let wif = "KzBwvPW6L5iwJSiE5vgS52Y69bUxfwizW3wF4C4Xa3ba3pdd7j63"

        XCTAssertEqual(WIF.decodeWIFCompressed(wif), key)
        XCTAssertEqual(WIF.encodeToWIFCompressed(key, networkType: .mainnet), wif)
    }
}
