//
//  ExtendedPrivateKey.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// BIP32 extended private key
public struct ExtendedPrivateKey: Equatable, Hashable, JSONStringConvertible, Codable {
    public let privateKey: Data
    public let chainCode: Data

    public let depth: Int
    public let parentFingerprint: Data
    public let childNumber: UInt32

    public init(privateKey: Data, chainCode: Data, depth: Int, parentFingerprint: Data, childNumber: UInt32) throws {
        self.privateKey = privateKey
        self.chainCode = chainCode
        self.depth = depth
        self.parentFingerprint = parentFingerprint
        self.childNumber = childNumber

        if depth == 0 && (parentFingerprint.contains(where: { $0 != 0 }) || childNumber != 0) {
            throw ExtendedKeySerializationError.wrongKey
        }
    }

    /// The master key
    /// - Parameters:
    ///   - privateKey: privateKey
    ///   - chainCode: chainCode
    public init(privateKey: Data, chainCode: Data) {
        self.privateKey = privateKey
        self.chainCode = chainCode
        self.depth = 0
        self.parentFingerprint = Data(hexString: "0x00000000")
        self.childNumber = 0
    }

    public func makePublicKey(for curve: EllipticCurve) throws -> ExtendedPublicKey {
        let publicKey = try CryptoUtils.makePublicKey(from: privateKey, curve: curve)

        return try ExtendedPublicKey(
            publicKey: publicKey,
            chainCode: chainCode,
            depth: depth,
            parentFingerprint: parentFingerprint,
            childNumber: childNumber
        )
    }

    public func serializeToWIFCompressed(for networkType: NetworkType) -> String {
        return WIF.encodeToWIFCompressed(privateKey, networkType: networkType)
    }
}

// MARK: - ExtendedKeySerializable

extension ExtendedPrivateKey: ExtendedKeySerializable {
    public init(from extendedKeyString: String, networkType: NetworkType) throws {
        guard let data = extendedKeyString.base58CheckDecodedData else {
            throw ExtendedKeySerializationError.decodingFailed
        }

        guard data.count == ExtendedKeySerializer.Constants.dataLength else {
            throw ExtendedKeySerializationError.wrongLength
        }

        let decodedVersion = UInt32(data.prefix(4).toInt()!) // it's safe to force unwrap here, because of size

        let version = ExtendedKeySerializer.Version.private

        guard decodedVersion == version.getPrefix(for: networkType) else {
            throw ExtendedKeySerializationError.wrongVersion
        }

        let depth = data.dropFirst(4).prefix(1).toInt()! // it's safe to force unwrap here, because of size
        let parentFingerprint = data.dropFirst(5).prefix(4)
        let childNumber = UInt32(data.dropFirst(9).prefix(4).toInt()!) // it's safe to force unwrap here, because of size
        let chainCode = data.dropFirst(13).prefix(32)
        let privateKey = data.suffix(32)
        let prefix = data.dropFirst(45).prefix(1)

        guard prefix == Data(UInt8(0)) else {
            throw ExtendedKeySerializationError.decodingFailed
        }

        guard Secp256k1Utils().isPrivateKeyValid(privateKey) else {
            throw TangemSdkError.unsupportedCurve
        }

        try self.init(
            privateKey: privateKey,
            chainCode: chainCode,
            depth: depth,
            parentFingerprint: parentFingerprint,
            childNumber: childNumber
        )
    }

    public func serialize(for networkType: NetworkType) throws -> String {
        var data = Data(capacity: ExtendedKeySerializer.Constants.dataLength)

        let version = ExtendedKeySerializer.Version.private

        data += version.getPrefix(for: networkType).bytes4
        data += depth.byte
        data += parentFingerprint
        data += childNumber.bytes4
        data += chainCode
        data += Data(UInt8(0)) + privateKey

        guard data.count == ExtendedKeySerializer.Constants.dataLength else {
            throw ExtendedKeySerializationError.wrongLength
        }

        let resultString = Array(data).base58CheckEncodedString
        return resultString
    }
}
