//
//  TlvLogging.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol TlvLogging {
    func logTlv<T>(_ tlv: Tlv, _ value: T)
}

extension TlvLogging {
    func logTlv<T>(_ tlv: Tlv, _ value: T) {
        guard !tlv.tag.shouldMask else {
            logMasked(tlv)
            return
        }

        var tlvString = "\(tlv)"
        
        if tlv.tag.valueType != .data && tlv.tag.valueType != .hexString {
            tlvString += " (\(value))"
        }
        
        Log.tlv(tlvString)
    }

    private func logMasked(_ tlv: Tlv) {
        let tagName = "\(tlv.tag)".capitalizingFirst()
        let tagFullName = "TAG_\(tagName)"

        Log.tlv("\(tagFullName) [0x\(tlv.tagRaw):***]: ***")
    }
}
