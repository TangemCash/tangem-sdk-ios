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

class CommonTests: XCTestCase {
    func testAtetstModeCompare() {
        XCTAssertTrue(AttestationTask.Mode.normal < AttestationTask.Mode.full)
        XCTAssertTrue(AttestationTask.Mode.normal <= AttestationTask.Mode.full)
        XCTAssertFalse(AttestationTask.Mode.normal > AttestationTask.Mode.full)
        XCTAssertFalse(AttestationTask.Mode.full < AttestationTask.Mode.normal)
        XCTAssertTrue(AttestationTask.Mode.full >= AttestationTask.Mode.normal)
        XCTAssertTrue(AttestationTask.Mode.full == AttestationTask.Mode.full)
        XCTAssertTrue(AttestationTask.Mode.normal == AttestationTask.Mode.normal)
        XCTAssertFalse(AttestationTask.Mode.full == AttestationTask.Mode.normal)
        XCTAssertFalse(AttestationTask.Mode.offline == AttestationTask.Mode.normal)
        XCTAssertFalse(AttestationTask.Mode.offline == AttestationTask.Mode.full)
        XCTAssertTrue(AttestationTask.Mode.full >= AttestationTask.Mode.offline)
        XCTAssertTrue(AttestationTask.Mode.normal >= AttestationTask.Mode.offline)
        XCTAssertTrue(AttestationTask.Mode.offline < AttestationTask.Mode.normal)
        XCTAssertTrue(AttestationTask.Mode.offline < AttestationTask.Mode.full)
        XCTAssertTrue(AttestationTask.Mode.full > AttestationTask.Mode.offline)
    }
    
    func testAttestationRawRepresentation() {
        let attestaion = Attestation(cardKeyAttestation: .verifiedOffline,
                                     walletKeysAttestation: .verified,
                                     firmwareAttestation: .skipped,
                                     cardUniquenessAttestation: .failed)
        
        let fromRepresentation = Attestation(rawRepresentation: attestaion.rawRepresentation)
        XCTAssertNotNil(fromRepresentation)
        XCTAssertEqual(attestaion, fromRepresentation)
    }
    
    func testCardIdFormatter() {
        func format(with style: CardIdDisplayFormat) -> String? {
            var formatter = CardIdFormatter()
            formatter.style = style

            let cardIdString = "CB79000000018201"
            let nbsp = " "
            let whitespace = " "

            return formatter.string(from: cardIdString)?.replacingOccurrences(of: nbsp, with: whitespace)
        }
        
        XCTAssertEqual(format(with: .full), "CB79 0000 0001 8201")
        XCTAssertEqual(format(with: .lastLunh(4)), "Card #1820")
        XCTAssertEqual(format(with: .last(1)), "Card #1")
        XCTAssertEqual(format(with: .last(2)), "Card #01")
        XCTAssertEqual(format(with: .last(4)), "Card #8201")
        XCTAssertEqual(format(with: .last(6)), "Card #01 8201")
        XCTAssertEqual(format(with: .last(20)), "Card #CB79 0000 0001 8201")
        XCTAssertEqual(format(with: .last(16)), "Card #CB79 0000 0001 8201")
    }
    
    func testFirmwareParse() {
        let dev = FirmwareVersion(stringValue: "4.45d SDK")
        XCTAssertEqual(dev.major, 4)
        XCTAssertEqual(dev.minor, 45)
        XCTAssertEqual(dev.patch, 0)
        XCTAssertEqual(dev.type, .sdk)
        
        let spec = FirmwareVersion(stringValue: "4.45 mfi")
        XCTAssertEqual(spec.major, 4)
        XCTAssertEqual(spec.minor, 45)
        XCTAssertEqual(spec.patch, 0)
        XCTAssertEqual(spec.type, .special)
        
        let spec1 = FirmwareVersion(stringValue: "4.45m")
        XCTAssertEqual(spec, spec1)
        
        let rel = FirmwareVersion(stringValue: "4.45r")
        XCTAssertEqual(rel.major, 4)
        XCTAssertEqual(rel.minor, 45)
        XCTAssertEqual(rel.patch, 0)
        XCTAssertEqual(rel.type, .release)
        
        let rel1 = FirmwareVersion(stringValue: "4.45")
        XCTAssertEqual(rel, rel1)
    }
}
