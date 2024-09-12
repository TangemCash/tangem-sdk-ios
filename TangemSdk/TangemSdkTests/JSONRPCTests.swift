//
//  JSONRPCTests.swift
//  TangemSdkTests
//
//  Created by Alexander Osokin on 21.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
@testable import TangemSdk

class JSONRPCTests: XCTestCase {
    var testCard: Card {
        get throws {
            let json = try Bundle.readFileAsString(name: "Card", in: .root)
            let data = json.data(using: .utf8)
            XCTAssertNotNil(data)
            return try JSONDecoder.tangemSdkDecoder.decode(Card.self, from: data!)
        }
    }

    func testDecodeMasterExtendedPublicKey() throws {
        let json =
        """
        {
            "publicKey": "0200300397571D99D41BB2A577E2CBE495C04AC5B9A97B7A4ECF999F23CE45E962",
            "chainCode": "537F7361175B150732E17508066982B42D9FB1F8239C4D7BFC490088C83A8BBB",
        }
        """

        let decoded = try JSONDecoder.tangemSdkDecoder.decode(ExtendedPublicKey.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(decoded.publicKey.hexString, "0200300397571D99D41BB2A577E2CBE495C04AC5B9A97B7A4ECF999F23CE45E962")
        XCTAssertEqual(decoded.chainCode.hexString, "537F7361175B150732E17508066982B42D9FB1F8239C4D7BFC490088C83A8BBB")
        XCTAssertEqual(decoded.depth, 0)
        XCTAssertEqual(decoded.childNumber, 0)
        XCTAssertEqual(decoded.parentFingerprint.hexString, "00000000")
    }

    func testDecodeInvalidExtendedPublicKey() throws {
        let json =
        """
        {
            "publicKey": "0200300397571D99D41BB2A577E2CBE495C04AC5B9A97B7A4ECF999F23CE45E962",
            "chainCode": "537F7361175B150732E17508066982B42D9FB1F8239C4D7BFC490088C83A8BBB",
            "depth" : 1,
        }
        """

        XCTAssertThrowsError(try JSONDecoder.tangemSdkDecoder.decode(ExtendedPublicKey.self, from: json.data(using: .utf8)!))
    }

    func testDecodeExtendedPublicKey() throws {
        let json =
        """
        {
            "publicKey": "0200300397571D99D41BB2A577E2CBE495C04AC5B9A97B7A4ECF999F23CE45E962",
            "chainCode": "537F7361175B150732E17508066982B42D9FB1F8239C4D7BFC490088C83A8BBB",
            "depth" : 1,
            "parentFingerprint" : "00000001",
            "childNumber" : 2
        }
        """

        let decoded = try JSONDecoder.tangemSdkDecoder.decode(ExtendedPublicKey.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(decoded.publicKey.hexString, "0200300397571D99D41BB2A577E2CBE495C04AC5B9A97B7A4ECF999F23CE45E962")
        XCTAssertEqual(decoded.chainCode.hexString, "537F7361175B150732E17508066982B42D9FB1F8239C4D7BFC490088C83A8BBB")
        XCTAssertEqual(decoded.depth, 1)
        XCTAssertEqual(decoded.childNumber, 2)
        XCTAssertEqual(decoded.parentFingerprint.hexString, "00000001")
    }
    
    func testJsonRPCRequestParse() {
        let json = "{\"jsonrpc\": \"2.0\", \"method\": \"subtract\", \"params\": {\"subtrahend\": 23, \"minuend\": 42}, \"id\": 3}"
        
        let request = try? JSONRPCRequest(jsonString: json)
        XCTAssertNotNil(request)
        XCTAssertEqual(request!.method, "subtract")
        XCTAssertEqual(request!.params["subtrahend"] as! Int, Int(23))
    }
    
    func testInitialMessageInit() {
        let json = "{\"header\": \"Some header\", \"body\": \"Some body\"}"
        
        if let message = Message(json) {
            XCTAssertEqual(message.header, "Some header")
            XCTAssertEqual(message.body, "Some body")
        } else {
            XCTAssertNotNil(nil)
        }
    }
    
    func testJsonResponse() {
        let response = SuccessResponse(cardId: "c000111122223333")
        let result: Result<SuccessResponse, TangemSdkError> = .success(response)
        let jsonResponse = result.toJsonResponse(id: 1).testJson
        let testResponse = "{\"id\":1,\"jsonrpc\":\"2.0\",\"result\":{\"cardId\":\"c000111122223333\"}}"
        XCTAssertEqual(jsonResponse, testResponse)
    }
    
    func testDecodeSingleHex() {
        var dict: [String: Any] = .init()
        dict["pubKey"] = "AABBCCDDEEFF"
        let data: Data = try! dict.value(for: "pubKey")
        XCTAssert(data == Data(hexString: "AABBCCDDEEFF"))
    }
    
    func testDecodeMultipleHex() {
        var dict: [String: Any] = .init()
        dict["hashes"] = ["AABBCCDDEEFF", "AABBCCDDEEFFGG"]
        let data: [Data] = try! dict.value(for: "hashes")
        XCTAssert(data[0] == Data(hexString: "AABBCCDDEEFF"))
        XCTAssert(data[1] == Data(hexString: "AABBCCDDEEFFGG"))
    }
    
    func testScan() throws {
        try testMethod(name: "Scan", in: .root, result: testCard)
    }
    
    func testCreateWallet() throws {
        let result = CreateWalletResponse(cardId: "c000111122223333",
                                          wallet: Card.Wallet(publicKey: Data(hexString: "5130869115a2ff91959774c99d4dc2873f0c41af3e0bb23d027ab16d39de1348"),
                                                              chainCode: nil,
                                                              curve: .secp256r1,
                                                              settings: Card.Wallet.Settings(isPermanent: true),
                                                              totalSignedHashes: 10,
                                                              remainingSignatures: 100,
                                                              index: 1,
                                                              proof: nil,
                                                              isImported: false,
                                                              hasBackup: false))
        try testMethod(name: "CreateWallet", in: .root, result: result)
    }

    func testImportWalletMnemonic() throws {
        let result = CreateWalletResponse(cardId: "c000111122223333",
                                          wallet: Card.Wallet(publicKey: Data(hexString: "029983A77B155ED3B3B9E1DDD223BD5AA073834C8F61113B2F1B883AAA70971B5F"),
                                                              chainCode: Data(hexString: "C7A888C4C670406E7AAEB6E86555CE0C4E738A337F9A9BC239F6D7E475110A4E"),
                                                              curve: .secp256k1,
                                                              settings: Card.Wallet.Settings(isPermanent: true),
                                                              totalSignedHashes: 10,
                                                              remainingSignatures: 100,
                                                              index: 1,
                                                              proof: nil,
                                                              isImported: false,
                                                              hasBackup: false))
        try testMethod(name: "ImportWalletMnemonic", in: .root, result: result)
    }
    
    func testPurgeWallet() throws {
        let result = PurgeWalletCommand.Response(cardId: "c000111122223333")
        try testMethod(name: "PurgeWallet", in: .root, result: result)
    }
    
    func testDepersonalize() throws {
        let result = DepersonalizeResponse(success: true)
        try testMethod(name: "Depersonalize", in: .root, result: result)
    }
    
    func testPersonalize() throws {
        try testPersonalizeConfig(name: "v4")
        try testPersonalizeConfig(name: "v3.05ada")
    }
    
    func testSetPin1() throws {
        let result = SuccessResponse(cardId: "c000111122223333")
        
        try testMethod(name: "SetAccessCode", in: .root, result: result)
    }
    
    func testSetPin2() throws {
        let result = SuccessResponse(cardId: "c000111122223333")
        
        try testMethod(name: "SetPasscode", in: .root, result: result)
    }
    
    func testSignHashes() throws {
        let result = SignHashesResponse(cardId: "c000111122223333",
                                        signatures: [Data(hexString: "eb7411c2b7d871c06dad51e58e44746583ad134f4e214e4899f2fc84802232a1"),
                                                     Data(hexString: "33443bd93f350b62a90a0c23d30c6d4e9bb164606e809ccace60cf0e2591e58c")],
                                        totalSignedHashes: 2)
        
        try testMethod(name: "SignHashes", in: .root, result: result)
    }
    
    func testSignHash() throws {
        let result = SignHashResponse(cardId: "c000111122223333",
                                      signature: Data(hexString: "eb7411c2b7d871c06dad51e58e44746583ad134f4e214e4899f2fc84802232a1"),
                                      totalSignedHashes: 2)
        
        try testMethod(name: "SignHash", in: .root, result: result)
    }
    
    func testDerivePublicKey() throws {
        let result = ExtendedPublicKey(publicKey: Data(hexString: "0200300397571D99D41BB2A577E2CBE495C04AC5B9A97B7A4ECF999F23CE45E962"),
                                       chainCode: Data(hexString: "537F7361175B150732E17508066982B42D9FB1F8239C4D7BFC490088C83A8BBB"))
        
        try testMethod(name: "DeriveWalletPublicKey", in: .root, result: result)
    }
    
    func testDerivePublicKeys() throws {
        let keys = [try! DerivationPath(rawPath: "m/44'/0'") : ExtendedPublicKey(publicKey: Data(hexString: "0200300397571D99D41BB2A577E2CBE495C04AC5B9A97B7A4ECF999F23CE45E962"),
                                                     chainCode: Data(hexString: "537F7361175B150732E17508066982B42D9FB1F8239C4D7BFC490088C83A8BBB")),
                    try! DerivationPath(rawPath: "m/44'/1'")  : ExtendedPublicKey(publicKey: Data(hexString: "0200300397571D99D41BB2A577E2CBE495C04AC5B9A97B7A4ECF999F23CE45E962"),
                                                     chainCode: Data(hexString: "537F7361175B150732E17508066982B42D9FB1F8239C4D7BFC490088C83A8BBB"))]
        let result = DerivedKeys(keys: keys)
        try testMethod(name: "DeriveWalletPublicKeys", in: .root, result: result)
    }

    func testUserCodeRecoveryAllowed() throws {
        let result = SuccessResponse(cardId: "c000111122223333")

        try testMethod(name: "SetUserCodeRecoveryAllowed", in: .root, result: result)
    }

    func testAttestCardKey() throws {
        let result = AttestCardKeyResponse(cardId: "c000111122223333",
                                           salt: Data(hexString: "BBBBBBBBBBBB"),
                                           cardSignature: Data(hexString: "AAAAAAAAAAAA"),
                                           challenge: Data(hexString: "000000000000"),
                                           linkedCardPublicKeys: [])

        try testMethod(name: "AttestCardKey", in: .root, result: result)
    }


    func testFiles() throws {
        try testMethod(name: "ReadFiles", in: .files, result: [File(data: Data(hexString: "00AABBCCDD"),
                                                    index: 0,
                                                    settings: FileSettings(isPermanent: false,
                                                                           visibility: .public))])

        try testMethod(name: "DeleteFiles", in: .files, result: DeleteFilesTask.Response(cardId: "c000111122223333"))
        try testMethod(name: "WriteFiles", in: .files, result: WriteFilesTask.Response(cardId: "c000111122223333", filesIndices: [0,1]))
        try testMethod(name: "ChangeFileSettings", in: .files, result: ChangeFileSettingsTask.Response(cardId: "c000111122223333"))
    }
    
    func testMethodNotFound() {
        let json = "{\"jsonrpc\": \"2.0\", \"method\": \"sign_task\", \"params\": {\"walletIndex\": \"AABBCCDDEEFFGGHHKKLLMMNN\", \"hashes\": [\"AABBCCDDEEFF\", \"AABBCCDDEEFFGG\"]}, \"id\": 1}"
        let request = try? JSONRPCRequest(jsonString: json)
        XCTAssertNotNil(request)
        do {
            _ = try JSONRPCConverter.shared.convert(request: request!)
            XCTAssertTrue(false)
        } catch {
            let jsError = error as? JSONRPCError
            XCTAssertNotNil(jsError)
            XCTAssertTrue(jsError!.code == JSONRPCError.Code.methodNotFound.rawValue)
        }
    }
    
    func testParseRequest() throws {
        let name = "TestParseRequest"
        let fileText = try Bundle.readFileAsString(name: name, in: .root)
        let jsonData = fileText.data(using: .utf8)!
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                  let array = json["array"],
                  let singleItem = json["singleItem"],
                  let request = json["singleRequest"] else {
                XCTAssert(false, "Failed to parse test json \(name)")
                return
            }
            
            let arrayData = try JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
            let singleItemData = try JSONSerialization.data(withJSONObject: singleItem, options: .prettyPrinted)
            let requestData = try JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
            
            guard let arrayValue = String(data: arrayData, encoding: .utf8),
                  let singleItemValue = String(data: singleItemData, encoding: .utf8),
                  let requestValue = String(data: requestData, encoding: .utf8) else {
                XCTAssert(false, "Failed to parse test json \(name)")
                return
            }
            
            
            let parser = JSONRPCRequestParser()
            let parsedArray = try parser.parse(jsonString: arrayValue)
            guard case .array = parsedArray else {
                XCTAssert(false, "Parsed result is not array")
                return
            }
            
            let parsedSingleItem = try parser.parse(jsonString: singleItemValue)
            guard case .array = parsedSingleItem else {
                XCTAssert(false, "Parsed result is not array")
                return
            }
            
            let parsedRequest = try parser.parse(jsonString: requestValue)
            guard case .single = parsedRequest else {
                XCTAssert(false, "Parsed result is not single request")
                return
            }
        
        } catch {
            print(error)
            XCTAssert(false, "Failed to parse test json \(name)")
        }
    }
    
    private func testPersonalizeConfig(name: String) throws {
        guard let testData = try getTestData(for: name, in: .personalize) else {
            XCTAssert(false, "Failed to create test data \(name)")
            return
        }
        
        //test request
        do {
           let request = try JSONRPCRequest(jsonString: testData.request)
            //test convert request
            XCTAssertNoThrow(try JSONRPCConverter.shared.convert(request: request))
        } catch {
            XCTAssert(false, "Failed to create request for \(name)")
            return
        }
    }
    
    private func testMethod<TResult: Encodable>(name: String, in folder: Bundle.Folder, result: TResult) throws {
        guard let testData = try getTestData(for: name, in: folder) else {
            XCTAssert(false, "Failed to create test data \(name)")
            return
        }
        
        //test request
        do {
           let request = try JSONRPCRequest(jsonString: testData.request)
            //test convert request
            XCTAssertNoThrow(try JSONRPCConverter.shared.convert(request: request))
        } catch {
            XCTAssert(false, "Failed to create request for \(name)")
            return
        }
        
        //test response
        guard let responseJson = try? JSONSerialization.jsonObject(with: testData.response, options: []) as? [String: Any],
              let resultValue = responseJson["result"],
              let resultJsonData = try? JSONSerialization.data(withJSONObject: resultValue, options: .sortedKeys),
              let resultData = try? JSONEncoder.tangemSdkTestEncoder.encode(result)
        else {
            XCTAssert(false, "Failed to parse test response for \(name)")
            return
        }
      
        XCTAssertEqual(resultData.utf8String!.lowercased(), resultJsonData.utf8String!.lowercased())
    }
    
    private func getTestData(for method: String, in folder: Bundle.Folder) throws -> (request: String, response: Data)? {
        let fileText = try Bundle.readFileAsString(name: method, in: folder)
        let jsonData = fileText.data(using: .utf8)!
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                  let request = json["request"] else {
                XCTAssert(false, "Failed to parse test json \(name)")
                return nil
            }
            
            let requestData = try JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
            
            let responseData: Data
            if let response = json["response"] {
                responseData = try JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
            } else {
                let cardResponse = "{\"result\": \(try testCard.json)}"
                responseData = cardResponse.data(using: .utf8)!
            }

            guard let requestValue = String(data: requestData, encoding: .utf8) else {
                XCTAssert(false, "Failed to parse test json \(name)")
                return nil
            }
            
            return (requestValue, responseData)
        } catch {
            print(error)
            XCTAssert(false, "Failed to parse test json \(name)")
            return nil
        }
    }
}
