//
//  HexConvertible.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// Convert hex data to Integer
public protocol HexConvertible {
    init?(hexData: Data)
}

public extension HexConvertible where Self: FixedWidthInteger {
    init?(hexData: Data) {
        guard let intValue = Self(hexData.hexString, radix: 16) else {
            return nil
        }

        self = intValue
    }
}

extension Int: HexConvertible {}
extension UInt64: HexConvertible {}
extension Int32: HexConvertible {}
