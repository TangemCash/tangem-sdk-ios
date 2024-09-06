//
//  ByteUtilsTest.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class ByteUtilsTests: XCTestCase {
    func testHexConversion() {
        let testData = UInt8(0x1B)
        let testString = "1B"
        XCTAssert(testString == testData.hexString)
    }
    
    func testInputStream() {
        let data = Data(hexString: "00010203040506")
        let inputStream = InputStream(data: data)
        inputStream.open()
        let bytes = inputStream.readBytes(count: 4)
        XCTAssertNotNil(bytes)
        XCTAssertEqual(bytes!, Data(hexString: "00010203"))
        let oneMoreByte = inputStream.readByte()
        XCTAssertNotNil(oneMoreByte)
        XCTAssertEqual(oneMoreByte!, UInt8(0x04))
        inputStream.close()
    }

    func testParseBits() throws {
        let testCases = ["10110111", "00000000", "11111111", "10000000", "00000001"]

        for testcase in testCases {
            let byte = try XCTUnwrap(UInt8(testcase, radix: 2))
            let bits = byte.toBits().joined()
            XCTAssertEqual(bits, testcase)
        }
    }
}
