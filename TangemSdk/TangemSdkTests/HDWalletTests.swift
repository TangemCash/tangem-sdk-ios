//
//  HDWalletTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 30.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class HDWalletTests: XCTestCase {
    func testDerivation1() {
        let masterKey = ExtendedPublicKey(publicKey: Data(hexString: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"),
                                          chainCode: Data(hexString: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"))
        
        let derived = try? masterKey.derivePublicKey(node: .nonHardened(1))
        XCTAssertNotNil(derived)
        
        let key = derived!.publicKey.hexString.lowercased()
        let chainCode = derived!.chainCode.hexString.lowercased()
        XCTAssertEqual(key, "037c2098fd2235660734667ff8821dbbe0e6592d43cfd86b5dde9ea7c839b93a50")
        XCTAssertEqual(chainCode, "8dd96414ff4d5b4750be3af7fecce207173f86d6b5f58f9366297180de8e109b")
    }
    
    func testDerivation0() {
        let masterKey = ExtendedPublicKey(publicKey: Data(hexString: "03cbcaa9c98c877a26977d00825c956a238e8dddfbd322cce4f74b0b5bd6ace4a7"),
                                          chainCode: Data(hexString: "60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689"))
        
        let derived = try? masterKey.derivePublicKey(node: .nonHardened(0))
        XCTAssertNotNil(derived)
        
        let key = derived!.publicKey.hexString.lowercased()
        let chainCode = derived!.chainCode.hexString.lowercased()
        XCTAssertEqual(key, "02fc9e5af0ac8d9b3cecfe2a888e2117ba3d089d8585886c9c826b6b22a98d12ea")
        XCTAssertEqual(chainCode, "f0909affaa7ee7abe5dd4e100598d4dc53cd709d5a5c2cac40e7412f232f7c9c")
    }
    
    func testParsePath() {
        let derivationPath = try? DerivationPath(rawPath: "m / 44' / 0' / 0' / 1 / 0")
        let derivationPath1 = try? DerivationPath(rawPath: "m/44'/0'/0'/1/0")
        let derivationPath2 = try? DerivationPath(rawPath: "M/44'/0'/0'/1/0")
        let derivationPath3 = DerivationPath(nodes: [.hardened(44), .hardened(0), .hardened(0), .nonHardened(1), .nonHardened(0)])
        let derivationPath4 = try? DerivationPath(rawPath: "m/44'/0’/0’/1/0") // alternative quotes
        XCTAssertNotNil(derivationPath)
        XCTAssertNotNil(derivationPath1)
        XCTAssertNotNil(derivationPath2)
        XCTAssertEqual(derivationPath?.nodes, derivationPath1?.nodes)
        XCTAssertEqual(derivationPath?.nodes, derivationPath2?.nodes)
        XCTAssertEqual(derivationPath?.nodes, derivationPath3.nodes)
        XCTAssertEqual(derivationPath?.nodes, derivationPath4?.nodes)
        
        XCTAssertEqual(derivationPath?.nodes[0], DerivationNode.hardened(44))
        XCTAssertEqual(derivationPath?.nodes[1], DerivationNode.hardened(0))
        XCTAssertEqual(derivationPath?.nodes[2], DerivationNode.hardened(0))
        XCTAssertEqual(derivationPath?.nodes[3], DerivationNode.nonHardened(1))
        XCTAssertEqual(derivationPath?.nodes[4], DerivationNode.nonHardened(0))
        
        let derivationPathWrong = try? DerivationPath(rawPath: "44'/m'/0'/1/0")
        XCTAssertNil(derivationPathWrong)
        let derivationPathWrong1 = try? DerivationPath(rawPath: "m /")
        XCTAssertNil(derivationPathWrong1)
        let derivationPathWrong2 = try? DerivationPath(rawPath: "m|44'|0'|0'|1|0")
        XCTAssertNil(derivationPathWrong2)
        let derivationPathWrong3 = try? DerivationPath(rawPath: "m/44'/0'/0''/1")
        XCTAssertNil(derivationPathWrong3)
        let derivationPathWrong4 = try? DerivationPath(rawPath: "m/44'/0'/'0'/1")
        XCTAssertNil(derivationPathWrong4)
        let derivationPathWrong5 = try? DerivationPath(rawPath: "m/44'/0'/1''3/1")
        XCTAssertNil(derivationPathWrong5)
        let derivationPathWrong6 = try? DerivationPath(rawPath: "m/44'/0'/0'//1/0")
        XCTAssertNil(derivationPathWrong6)
        let derivationPathWrong7 = try? DerivationPath(rawPath: "m/'44/’0/’0/1/0")
        XCTAssertNil(derivationPathWrong7)
        let derivationPathWrong8 = try? DerivationPath(rawPath: "m'/44'/0'/0'/1/0") // m' <---
        XCTAssertNil(derivationPathWrong8)
        
        let derivationPathNormalized = try! DerivationPath(rawPath: "m/44'/0'/0/1'/1/5/5'/9/9'")
        let derivationPathNotNormalized = try! DerivationPath(rawPath: "m/044'/00'/00/001'/001/00005/00005'/00000000000000000000000000009/00000000000000000000000000009'")
        XCTAssertEqual(derivationPathNormalized, derivationPathNotNormalized)
    }
    
    func testTlvSerialization() {
        let path = try! DerivationPath(rawPath: "m/0/1")
        let tlv = path.encodeTlv(with: .walletHDPath)
        let hexValue = tlv.value.hexString
        XCTAssertEqual("0000000000000001", hexValue)
        
        let path1 = try! DerivationPath(rawPath: "m/0'/1'/2")
        let tlv1 = path1.encodeTlv(with: .walletHDPath)
        let hexValue1 = tlv1.value.hexString
        XCTAssertEqual("800000008000000100000002", hexValue1)
    }
    
    func testTlvDeserialization() {
        let path = try! DerivationPath(from: Data(hexString: "0000000000000001"))
        XCTAssertEqual("m/0/1", path.rawPath)
        
        let path1 = try! DerivationPath(from: Data(hexString: "800000008000000100000002"))
        XCTAssertEqual("m/0'/1'/2", path1.rawPath)
        
        let nilPath = try? DerivationPath(from: Data(hexString: "000000000000000100"))
        XCTAssertNil(nilPath)
    }
    
    func testBitcoinBip44() {
        let buidler = BIP44(coinType: 0,
                            account: 0,
                            change: .external,
                            addressIndex: 0)
        let path = buidler.buildPath().rawPath
        XCTAssertEqual(path, "m/44'/0'/0'/0/0")
    }
    
    func testPathDerivation() {
        let path = try! DerivationPath(rawPath: "m/0")
        
        let masterKey = ExtendedPublicKey(publicKey: Data(hexString: "03cbcaa9c98c877a26977d00825c956a238e8dddfbd322cce4f74b0b5bd6ace4a7"),
                                          chainCode: Data(hexString: "60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689"))
        
        let childKey = try? masterKey.derivePublicKey(path: path)
        XCTAssertEqual(childKey?.chainCode.hexString.lowercased(),
                       "f0909affaa7ee7abe5dd4e100598d4dc53cd709d5a5c2cac40e7412f232f7c9c")
        XCTAssertEqual(childKey?.publicKey.hexString.lowercased(), "02fc9e5af0ac8d9b3cecfe2a888e2117ba3d089d8585886c9c826b6b22a98d12ea")
    }
    
    func testPathDerivation1() {
        let path = try! DerivationPath(rawPath: "m/0/1")
        //xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8doc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB
        let masterKey = ExtendedPublicKey(publicKey: Data(hexString: "03cbcaa9c98c877a26977d00825c956a238e8dddfbd322cce4f74b0b5bd6ace4a7"),
                                          chainCode: Data(hexString: "60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689"))
        
        let childKey = try? masterKey.derivePublicKey(path: path)
        
        XCTAssertEqual(childKey?.chainCode.hexString.lowercased(),
                       "8d5e25bfe038e4ef37e2c5ec963b7a7c7a745b4319bff873fc40f1a52c7d6fd1")
        XCTAssertEqual(childKey?.publicKey.hexString.lowercased(),
                       "02d27a781fd1b3ec5ba5017ca55b9b900fde598459a0204597b37e6c66a0e35c98")
    }
    
    func testPathDerivationFailed() {
        let buidler = BIP44(coinType: 0,
                            account: 0,
                            change: .external,
                            addressIndex: 0)
        
        let path = buidler.buildPath()
        
        let masterKey = ExtendedPublicKey(publicKey: Data(hexString: "03cbcaa9c98c877a26977d00825c956a238e8dddfbd322cce4f74b0b5bd6ace4a7"),
                                          chainCode: Data(hexString: "60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689"))
        
        XCTAssertThrowsError(try masterKey.derivePublicKey(path: path)) { error in
            let hdError = error as? HDWalletError
            XCTAssertEqual(HDWalletError.hardenedNotSupported, hdError)
        }
    }
    
    func testCodableDerivationPath() {
        let derivationPath = try! DerivationPath(rawPath: "m/44'/0'/0'/1/0")
        let encodedData = try! JSONEncoder().encode(derivationPath)
        let decodedDerivationPath = try! JSONDecoder().decode(DerivationPath.self, from: encodedData)
        XCTAssertEqual(derivationPath, decodedDerivationPath)
    }
    
    func testPathExtension() {
        let derivationPath = try! DerivationPath(rawPath: "m/44'/0'/0'/1")
        let extendedPath = derivationPath.extendedPath(with: .nonHardened(0))
        XCTAssertEqual(extendedPath.rawPath, "m/44'/0'/0'/1/0")
    }
}
