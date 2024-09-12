//
//  IntUtilsTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class IntUtilsTests: XCTestCase {
    func testFromHexConversion() {
        let testData = Data(hexString: "9569")
        XCTAssertEqual(38249, Int(hexData: testData))
    }

    func testFromHexConversionOverflow() {
        let testData = Data(hexString: "FFFFFFFFFFFFFFFF")
        XCTAssertNil(Int(hexData: testData))
    }

    func testUInt64FromHexConversion() {
        let testData = Data(hexString: "FFFFFFFFFFFFFFFF")
        XCTAssertEqual(18446744073709551615, UInt64(hexData: testData))
    }

    func testUInt64FromHexConversionOverflow() {
        let testData = Data(hexString: "FFFFFFFFFFFFFFFF01")
        XCTAssertNil(Int(hexData: testData))
    }
    
    func testToByteConversion() {
        XCTAssertEqual(15.byte, Data(hexString: "0F"))
        XCTAssertEqual(356.bytes2, Data(hexString: "0164"))
        XCTAssertEqual(3456988.bytes4, Data(hexString: "0034BFDC"))
        XCTAssertEqual(345698858557552.bytes8, Data(hexString: "00013A6949A9E070"))
    }
}
