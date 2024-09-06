//
//  Byte+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

public typealias Byte = UInt8

extension UInt8 {
    public var description: String {
        return hexString
    }
    
    public var hexString: String {
        return String(format: "%02X", self)
    }

    func toBits() -> [String] {
        let totalBitsCount = 8

        var bits = [String](repeating: "0", count: totalBitsCount)

        for index in 0..<totalBitsCount {
            let mask: UInt8 = 1 << UInt8(totalBitsCount - 1 - index)
            let currentBit = self & mask

            if currentBit != 0 {
                bits[index] = "1"
            }
        }

        return bits
    }
}

extension UInt16 {
    public var description: String {
        return hexString
    }
    
    public var hexString: String {
        return String(format: "%02X", self)
    }
}

extension Array where Element == UInt8 {
    public func getSha256() -> Data {
        let digest = SHA256.hash(data: self)
        return Data(digest)
    }

    public func getSha512() -> Data {
        let digest = SHA512.hash(data: self)
        return Data(digest)
    }

    public func getDoubleSha256() -> Data {
        return getSha256().getSha256()
    }
}
