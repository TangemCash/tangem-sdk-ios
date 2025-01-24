//
//  CommandApdu.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/// Class that provides conversion of serialized request and Instruction code
/// to a raw data that can be sent to the card.
public struct CommandApdu: Equatable {
    /// Instruction code that determines the type of request for the card.
    let ins: Byte
    
    //MARK: Header
    fileprivate let cla: Byte

    fileprivate let p1:  Byte
    fileprivate let p2:  Byte
    
    //MARK: Body
    /// An array of  serialized TLVs that are to be sent to the card
    fileprivate let data: Data
    fileprivate let le: Int?
    
    /// Convinience initializer
    /// - Parameter instruction: Instruction code
    /// - Parameter tlv: data
    public init(_ instruction: Instruction, tlv: Data) {
        self.init(ins: instruction.rawValue, tlv: tlv)
    }
    
    /// Raw initializer
    /// - Parameter cla: Instruction class (CLA) byte
    /// - Parameter ins: Instruction code (INS) byte
    /// - Parameter p1:  P1 parameter byte
    /// - Parameter p2:  P2 parameter byte
    /// - Parameter le:  Optional Le value.
    /// Valid values from 1 to 65535. Pass 0 to send 65536.
    /// Values exceeding 65535 will be clamped to 65535.
    /// Negative values will be clamped to 0.
    /// - Parameter tlv: Payload data
    public init(cla: Byte = 0x00,
                ins: Byte,
                p1: Byte = 0x0,
                p2: Byte = 0x0,
                le: Int? = nil,
                tlv: Data) {
        self.cla = cla
        self.ins = ins
        self.p1 = p1
        self.p2 = p2
        self.le = le
        data = tlv
    }
    
    /// Encrypt APDU
    /// - Parameters:
    /// - Parameter encryptionMode: encryption mode
    /// - Parameter encryptionKey: encryption key
    /// - Returns: Encrypted APDU
    public func encrypt(encryptionMode: EncryptionMode, encryptionKey: Data?) throws -> CommandApdu {
        guard let encryptionKey = encryptionKey, p1 == EncryptionMode.none.byteValue else { //skip if already encrypted or empty encryptionKey
            return self
        }
        
        let crc = data.crc16()
        let tlvDataToEncrypt = data.count.bytes2 + crc + data
        let encryptedPayload = try tlvDataToEncrypt.encrypt(with: encryptionKey)
        Log.apdu("C-APDU encrypted")

        return CommandApdu(cla: self.cla, ins: self.ins, p1: encryptionMode.byteValue, p2: self.p2, le: self.le, tlv: Data(encryptedPayload))
    }
    
    /// Serialize as an extended APDU
    /// - Returns: Data to send
    public func serialize() -> Data {
        var apduBytes: Data = .init()
        apduBytes.append(cla)
        apduBytes.append(ins)
        apduBytes.append(p1)
        apduBytes.append(p2)
        
        if !data.isEmpty {
            //append LC as an extended field
            apduBytes.append(UInt8(0))
            apduBytes.append(contentsOf: data.count.bytes2)
            
            apduBytes.append(contentsOf: data)
        }
        
        if let le = le {
            //append LE as an extended field
            apduBytes.append(contentsOf: le.bytes2)
        }
        
        return apduBytes
    }
}

extension CommandApdu: CustomStringConvertible {
    public var description: String {
        let instruction = Instruction(rawValue: ins) ?? .unknown
        let bytes = serialize()
        return "\(instruction) [\(bytes.count) bytes]: \(bytes)"
    }
}
