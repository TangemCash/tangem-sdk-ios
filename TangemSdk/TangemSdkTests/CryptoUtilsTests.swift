//
//  TangemSdkTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 02/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemSdk
import CryptoKit

class CryptoUtilsTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGeneratePrivateKey() {
        let privateKey = try! CryptoUtils.generateRandomBytes(count: 32)
        XCTAssertNotNil(privateKey)
        XCTAssertEqual(privateKey.count, 32)
    }
    
    func testSecp256k1Sign() {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        let message = Data(repeating: UInt8(1), count: 64)
        let signature = try! Secp256k1Utils().sign(message, with: privateKey)
        XCTAssertNotNil(signature)
        
        let verify = try! CryptoUtils.verify(curve: .secp256k1, publicKey: publicKey, message: message, signature: signature)
        let verifyByHash = try! CryptoUtils.verify(curve: .secp256k1, publicKey: publicKey, hash: message.getSha256(), signature: signature)
        XCTAssertNotNil(verify)
        XCTAssertEqual(verify, true)
        XCTAssertNotNil(verifyByHash)
        XCTAssertEqual(verifyByHash, true)
    }
    
    func testEd25519Sign() {
        let privateKey = try! CryptoUtils.generateRandomBytes(count: 32)
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        let message = Data(hexString: "0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let signature = try! message.sign(privateKey: privateKey, curve: .ed25519)
        
        let verify = try? CryptoUtils.verify(curve: .ed25519, publicKey: publicKey, message: message, signature: signature)
        let verifyByHash = try? CryptoUtils.verify(curve: .ed25519, publicKey: publicKey, hash: message.getSha512(), signature: signature)
        XCTAssertNotNil(verify)
        XCTAssertNotNil(verifyByHash)
        XCTAssertEqual(verify, true)
        XCTAssertEqual(verifyByHash, true)
    }
    
    func testP256Sign() {
        let privateKey = try! CryptoUtils.generateRandomBytes(count: 32)
        let publicKey = try! P256.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.x963Representation
        let message = Data(hexString: "0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let signature = try! message.sign(privateKey: privateKey, curve: .secp256r1)
        
        let verify = try? CryptoUtils.verify(curve: .secp256r1, publicKey: publicKey, message: message, signature: signature)
        let verifyByHash = try? CryptoUtils.verify(curve: .secp256r1, publicKey: publicKey, hash: message.getSha256(), signature: signature)
        XCTAssertNotNil(verify)
        XCTAssertNotNil(verifyByHash)
        XCTAssertEqual(verify, true)
        XCTAssertEqual(verifyByHash, true)
    }
    
    func testEd25519Verify() {
        let publicKey = Data(hexString:"1C985027CBDD3326E58BF01311828588616855CBDFA15E46A20325AAE8BABE9A")
        let message = Data(hexString:"0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let signature = Data(hexString: "47F4C419E28013589433DBD771D618D990F4564BDAF6135039A8DF6A0803A3E3D84C3702514512C22E928C875495CA0EAC186AF0B23663924179D41830D6BF09")
        let hash = message.getSha512()
        var verify: Bool? = nil
        var verifyByHash: Bool? = nil
        measure {
            verify = try? CryptoUtils.verify(curve: .ed25519, publicKey: publicKey, message: message, signature: signature)
            verifyByHash = try? CryptoUtils.verify(curve: .ed25519, publicKey: publicKey, hash: hash, signature: signature)
        }
        
        XCTAssertNotNil(verify)
        XCTAssertEqual(verify, true)
        XCTAssertNotNil(verify)
        XCTAssertEqual(verifyByHash, true)
    }
    
    func testP256Verify() {
        let privateKeyData = try! CryptoUtils.generateRandomBytes(count: 32)
        let privateKey = try! P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
        let publicKey = privateKey.publicKey.x963Representation
        let message = Data(hexString:"0DA5A5EDA1F8B4F52DA5F92C2DC40346AAFE8C180DA3AD811F6F5AE7CCFB387D")
        let hash = message.getSha256()
        let signature = try! privateKey.signature(for: message).rawRepresentation
        
        var verify: Bool? = nil
        var verifyByHash: Bool? = nil
        measure {
            verify = try? CryptoUtils.verify(curve: .secp256r1, publicKey: publicKey, message: message, signature: signature)
            verifyByHash = try? CryptoUtils.verify(curve: .secp256r1, publicKey: publicKey, hash: hash, signature: signature)
        }
        
        XCTAssertNotNil(verify)
        XCTAssertEqual(verifyByHash, true)
        
        XCTAssertNotNil(verify)
        XCTAssertEqual(verifyByHash, true)
    }
    
    func testKeyCompression() {
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        
        let compressedKey = try! Secp256k1Key(with: publicKey).compress()
        XCTAssertEqual(compressedKey.hexString.lowercased(), "0232f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd")
        let decompressedKey = try! Secp256k1Key(with: compressedKey).decompress()
        XCTAssertEqual(decompressedKey,publicKey)
        
        let testKeyCompressed = try! Secp256k1Key(with: publicKey).compress()
        let testKeyCompressed2 = try! Secp256k1Key(with: testKeyCompressed).compress()
        XCTAssertEqual(testKeyCompressed.hexString.lowercased(), "0232f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd")
        XCTAssertEqual(testKeyCompressed, testKeyCompressed2)
        let testKeyDecompressed = try! Secp256k1Key(with: testKeyCompressed).decompress()
        let testKeyDecompressed2 = try! Secp256k1Key(with: testKeyDecompressed).decompress()
        XCTAssertEqual(testKeyDecompressed, publicKey)
        XCTAssertEqual(testKeyDecompressed, testKeyDecompressed2)
        
        let edKey = Data(hexString:"1C985027CBDD3326E58BF01311828588616855CBDFA15E46A20325AAE8BABE9A")
        XCTAssertThrowsError(try Secp256k1Key(with: edKey).compress())
        XCTAssertThrowsError(try Secp256k1Key(with: edKey).decompress())
    }
    
    func testNormalize() {
        let sigData = Data(hexString: "5365F955FC45763383936BBC021A15D583E8D2300D1A65D21853B6A0FCAECE4ED65093BB5EC5291EC7CC95B4278D0E9EF59719DE985EEB764779F511E453EDDD")
        let sig = try! Secp256k1Signature(with: sigData)
        
        let normalized = try! sig.normalize()
        XCTAssertEqual(normalized.hexString, "5365F955FC45763383936BBC021A15D583E8D2300D1A65D21853B6A0FCAECE4E29AF6C44A13AD6E138336A4BD872F15FC517C30816E9B4C57858697AEBE25364")
    }
    
    func testSignatureUnmarshal() {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        
        let dummyData = Data(repeating: UInt8(1), count: 64)
        let hash = dummyData.getSha256()
        let signature = try! Secp256k1Utils().sign(dummyData, with: privateKey)
        let unmarshalled = try? Secp256k1Signature(with: signature).unmarshal(with: publicKey, hash: hash)
        XCTAssertEqual(unmarshalled?.r.hexString, "1CF364E34E445A99AD7DBE616A93053E58C6B72A8C4F9158E506DE7C0DB3A3B3")
        XCTAssertEqual(unmarshalled?.s.hexString, "4D5A1F20E671A6CC57D2A46FC28488C833B4337B5C37089B99BBC16707459BA1")
        XCTAssertEqual(unmarshalled?.v.hexString, "1C")
    }

    func testRecoverPublicKey() throws {
        let privateKey = Data(hexString: "fd230007d4a39352f50d8c481456c1f86ddc5ff155df170af0100a62269852f0")
        let publicKey = Data(hexString: "0432f507f6a3029028faa5913838c50f5ff3355b9b000b51889d03a2bdb96570cd750e8187482a27ca9d2dd0c92c632155d0384521ed406753c9883621ad0da68c")
        let dummyData = Data(repeating: UInt8(1), count: 64)
        let hash = dummyData.getSha256()

        let signature = try Secp256k1Utils().sign(dummyData, with: privateKey)
        let unmarshalled = try Secp256k1Signature(with: signature).unmarshal(with: publicKey, hash: hash)

        let key = try Secp256k1Key(with: unmarshalled, hash: hash)
        XCTAssertEqual(try key.decompress().hexString, publicKey.hexString)

        let key1 = try Secp256k1Key(with: unmarshalled, message: dummyData)
        XCTAssertEqual(try key1.decompress().hexString, publicKey.hexString)
    }

    func testSecp256k1PrivateKeyValidation() {
        let utils = Secp256k1Utils()

        XCTAssertFalse(utils.isPrivateKeyValid(Data()))
        XCTAssertFalse(utils.isPrivateKeyValid(Data(repeating: UInt8(0), count: 32)))
    }

    func testSecp256r1PrivateKeyValidation() throws {
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(), curve: .secp256r1))
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(repeating: UInt8(0), count: 32), curve: .secp256r1))
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(hexString: "FFFFFFFFFE92BF972115EB5008573E60811CA5A79B40EAAF9036189360F47413"), curve: .secp256r1))
        XCTAssertFalse(try CryptoUtils.isPrivateKeyValid(Data(hexString: "FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC4FC632551"), curve: .secp256r1))
        XCTAssertTrue(try CryptoUtils.isPrivateKeyValid(Data(hexString: "FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632550"), curve: .secp256r1))
    }

    func testSchnorrVerifyByHash() throws {
        let publicKey = Data(hexString: "208BDB9C192B5DE5DDEBA9CA8500EEC10DECB9A0980C4664F5B168F6B37EB92A")
        let hash = Data(hexString: "0000000000000000000000000000000000000000000000000000000000000000")
        let signature = Data(hexString: "735951D8481B99777AB0ABADEFDA903E485756DE3599E75AF655B7F26CB7634956DEDEB89DB3E40A7B9ED095E5855290F8EB85C22E57A001A4A64385AB11A5B3")

        let verify = try CryptoUtils.verify(curve: .bip0340, publicKey: publicKey, hash: hash, signature: signature)
        XCTAssertEqual(verify, true)
    }

    func testSchnorrVerifyByMessage() throws {
        let publicKey = Data(hexString: "DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659")
        let message = Data(hexString: "243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89")
        let signature = Data(hexString: "0560D3B34117AAE83F028AB92B3F8C16E3FDA34D55D3C7A2E1F2EDFE0A0071491D8D2302A6810FC017EE4CBF6BF13ADF36F9C0967FFCFE1A64BCBBDA73CA813B")

        let verify = try CryptoUtils.verify(curve: .bip0340, publicKey: publicKey, message: message, signature: signature)
        XCTAssertEqual(verify, true)
    }

    func testECDHbyX() throws {
        let u = Secp256k1Utils()
        let keyPair1 = try u.generateKeyPair()
        let keyPair2 = try u.generateKeyPair()
        let sharedSecret1 = try u.getSharedSecret(privateKey: keyPair1.privateKey, publicKey: keyPair2.publicKey)
        let sharedSecret2 = try u.getSharedSecret(privateKey: keyPair2.privateKey, publicKey: keyPair1.publicKey)
        XCTAssertEqual(sharedSecret1, sharedSecret2)
    }
}
