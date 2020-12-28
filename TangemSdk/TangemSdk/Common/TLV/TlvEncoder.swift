//
//  TlvEncoder.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public final class TlvEncoder {
    public func encode<T>(_ tag: TlvTag, value: T?) throws -> Tlv {
        if let value = value {
            return try Tlv(tag, value: encode(value, for: tag))
        } else {
            print("Encoding error. Value for tag \(tag) is nil")
            throw TangemSdkError.encodingFailed
        }
    }
    
    private func encode<T>(_ value: T, for tag: TlvTag) throws -> Data {
        switch tag.valueType {
        case .hexString:
            try typeCheck(value, String.self)
            return Data(hexString: value as! String)
        case .utf8String:
            try typeCheck(value, String.self)
            let string = value as! String + "\0"
            if let data = string.data(using: .utf8) {
                return data
            } else {
                print("Encoding error. Failed to convert string to utf8 Data")
                throw TangemSdkError.encodingFailed
            }
        case .byte:
            try typeCheck(value, Int.self)
            return (value as! Int).byte
        case .intValue:
            try typeCheck(value, Int.self)
            return (value as! Int).bytes4
        case .uint16:
            try typeCheck(value, Int.self)
            return (value as! Int).bytes2
        case .boolValue:
            try typeCheck(value, Bool.self)
            let value = value as! Bool
            return value ? Data([Byte(1)]) : Data([Byte(0)])
        case .data:
            try typeCheck(value, Data.self)
            return value as! Data
        case .ellipticCurve:
            try typeCheck(value, EllipticCurve.self)
            let curve = value as! EllipticCurve
            if let data = (curve.rawValue + "\0").data(using: .utf8) {
                return data
            } else {
                print("Encoding error. Failed to convert EllipticCurve to utf8 Data")
                throw TangemSdkError.encodingFailed
            }
        case .dateTime:
            try typeCheck(value, Date.self)
            let date = value as! Date
            let calendar = Calendar(identifier: .gregorian)
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date)
            let d = calendar.component(.day, from: date)
            return y.bytes2 + m.byte + d.byte
        case .productMask:
            try typeCheck(value, ProductMask.self)
            let mask = value as! ProductMask
            return Data([mask.rawValue])
        case .settingsMask:
			do {
				try typeCheck(value, SettingsMask.self)
				let mask = value as! SettingsMask
				let rawValue = mask.rawValue
				if 0xFFFF0000 & rawValue != 0 {
					 return rawValue.bytes4
				} else {
					 return rawValue.bytes2
				}
			} catch {
				print("Settings mask type is not Card settings mask. Trying to check WalletSettingsMask")
			}
			
			try typeCheck(value, WalletSettingsMask.self)
			let mask = value as! WalletSettingsMask
			return mask.rawValue.bytes4
        case .cardStatus:
            try typeCheck(value, CardStatus.self)
            let status = value as! CardStatus
            return status.rawValue.byte
        case .signingMethod:
            try typeCheck(value, SigningMethod.self)
            let method = value as! SigningMethod
            return Data([method.rawValue])
        case .interactionMode:
			do {
				try typeCheck(value, IssuerExtraDataMode.self)
				let mode = value as! IssuerExtraDataMode
				return Data([mode.rawValue])
			} catch {
				print("Interaction mode is not and issuer. Trying to check FileDataMode")
			}
			try typeCheck(value, FileDataMode.self)
			let mode = value as! FileDataMode
			return Data([mode.rawValue])
		case .fileSettings:
			try typeCheck(value, FileSettings.self)
			let settings = value as! FileSettings
			return settings.rawValue.bytes2
        }
    }
    
    private func typeCheck<FromType, ToType>(_ value: FromType, _ to: ToType) throws {
        guard type(of: value) is ToType else {
            print("Encoding error. Value is \(FromType.self). Expected: \(ToType.self)")
            throw TangemSdkError.encodingFailedTypeMismatch
        }
    }
}
