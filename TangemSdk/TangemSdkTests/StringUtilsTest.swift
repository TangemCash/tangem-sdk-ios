//
//  StringUtilsTest.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 01.11.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk

class StringUtilsTest: XCTestCase {
    func testRemove() {
        let testString = "This is a test string"
        let newString = "This is a  string"
        XCTAssertEqual(testString.remove("test"), newString)
    }
    
    func testSha256() {
        let testSrting = "abc"
        let testSha = Data(hexString: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        
        let testSrting1 = ""
        let testSha1 = Data(hexString: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual(testSrting.sha256(), testSha)
        
        XCTAssertEqual(testSrting1.sha256(), testSha1)
    }
    
    func testSha256Empty() {
       
    }
    
    func testSha512() {
        let testSrting = "test string"
        let testSha = Data(hexString: "10e6d647af44624442f388c2c14a787ff8b17e6165b83d767ec047768d8cbcb71a1a3226e7cc7816bc79c0427d94a9da688c41a3992c7bf5e4d7cc3e0be5dbac")
        XCTAssertEqual(testSrting.sha512(), testSha)
    }
}
