//
//  Base58Tests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 13.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class Base58Tests: XCTestCase {
    func testRoundTrip() {
        let data = Data(repeating: UInt8(1), count: 32)
        XCTAssertEqual(data.base58CheckEncodedString.base58CheckDecodedData, data)
        XCTAssertEqual(data.base58EncodedString.base58DecodedData, data)

        let array = [UInt8](repeating: UInt8(1), count: 32)
        XCTAssertEqual(array.base58CheckEncodedString.base58CheckDecodedBytes, array)
        XCTAssertEqual(array.base58EncodedString.base58DecodedBytes, array)
    }

    func testBase58() {
        let ethalonString = "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L"
        let testData = Data(hexString: "00eb15231dfceb60925886b67d065299925915aeb172c06647")
        XCTAssertEqual(ethalonString, testData.base58EncodedString)
    }
}
