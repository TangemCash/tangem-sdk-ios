//
//  LegcayModeService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/// Manage legacy mode, according to iPhone model and app preferences. This feature fixes NFC issues with long-running commands and security delay for iPhone 7/7+. Tangem card firmware starts from 2.39
public class NFCUtils {
    /// Check if the current device doesn't support the desired NFC operations
    public static var isNFCAvailable: Bool {
        if NSClassFromString("NFCNDEFReaderSession") == nil { return false }

        return NFCNDEFReaderSession.readingAvailable
    }

    public static var isPoorNfcQualityDevice: Bool {
        return poorNFCQualityDevices.contains(identifier)
    }

    static var isBrokenRestartPollingDevice: Bool {
        return !correctRestartPollingDevices.contains(identifier)
    }

    // iPhone 7 family
    private static let poorNFCQualityDevices = ["iPhone9,1", "iPhone9,3", "iPhone9,2", "iPhone9,4"]

    // iPhone 14 Pro/Pro Max and iPhone 15 Pro have issues with restarting polling after 20 seconds from the first connection on iOS 17+. We assume that all new devices have this behavior. We have no confirmed cases for iPhone 14/14 Plus ("iPhone14,7", "iPhone14,8") at this time.
    private static let correctRestartPollingDevices = [
        "iPhone9,1", // iPhone 7 family
        "iPhone9,2",
        "iPhone9,3",
        "iPhone9,4",
        "iPhone10,1", // iPhone 8 family
        "iPhone10,2",
        "iPhone10,3",
        "iPhone10,4",
        "iPhone10,5",
        "iPhone10,6", // iPhone X family
        "iPhone11,2",
        "iPhone11,4",
        "iPhone11,6",
        "iPhone11,8",
        "iPhone12,1", // iPhone 11 family
        "iPhone12,3",
        "iPhone12,5",
        "iPhone12,8", // iPhone SE 2nd-generation
        "iPhone13,1", // iPhone 12 family
        "iPhone13,2",
        "iPhone13,3",
        "iPhone13,4",
        "iPhone14,2", // iPhone 13 family
        "iPhone14,3",
        "iPhone14,4",
        "iPhone14,5",
        "iPhone14,6", // iPhone SE 3rd-generation
        "iPhone14,7", // iPhone 14. Not confirmed
        "iPhone14,8", // iPhone 14 Plus. Not confirmed
    ]

    private static var identifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()

}
