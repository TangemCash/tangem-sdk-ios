//
//  ExtendedPublicKey.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 30.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

public struct ExtendedPublicKey: Equatable, Hashable, JSONStringConvertible {
    public let publicKey: Data
    public let chainCode: Data

    public let depth: Int
    public let parentFingerprint: Data
    public let childNumber: UInt32

    public init(publicKey: Data, chainCode: Data, depth: Int, parentFingerprint: Data, childNumber: UInt32) throws {
        self.depth = depth
        self.parentFingerprint = parentFingerprint
        self.childNumber = childNumber
        self.chainCode = chainCode
        self.publicKey = publicKey

        if depth == 0 && (parentFingerprint.contains(where: { $0 != 0 }) || childNumber != 0) {
            throw ExtendedKeySerializationError.wrongKey
        }
    }

    /// The master key
    /// - Parameters:
    ///   - publicKey: publicKey
    ///   - chainCode: chainCode
    public init(publicKey: Data, chainCode: Data) {
        try! self.init(publicKey: publicKey,
                       chainCode: chainCode,
                       depth: 0,
                       parentFingerprint: Data(hexString: "0x00000000"),
                       childNumber: 0)
    }
    
    /// This function performs CKDpub((Kpar, cpar), i) → (Ki, ci) to compute a child extended public key from the parent extended public key.
    ///  It is only defined for non-hardened child keys. `secp256k1` only
    public func derivePublicKey(node: DerivationNode) throws -> ExtendedPublicKey {
        guard (try? Secp256k1Key(with: publicKey)) != nil else {
            throw TangemSdkError.unsupportedCurve
        }
        
        let index = node.index
        
        //We can derive only non-hardened keys
        guard index < BIP32.Constants.hardenedOffset else {
            throw HDWalletError.hardenedNotSupported
        }
        
        //let I = HMAC-SHA512(Key = cpar, Data = serP(Kpar) || ser32(i)).
        let data = publicKey + index.bytes4
        let hmac = HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: chainCode))
        let digest = Data(hmac)
        
        let secp256k1 = Secp256k1Utils()
        let ki = try secp256k1.createPublicKey(privateKey: digest[0..<32], compressed: true)
        let derivedPublicKey = try secp256k1.sum(compressedPubKey1: ki, compressedPubKey2: publicKey)
        let derivedChainCode = digest[32..<64]

        return try ExtendedPublicKey(
            publicKey: derivedPublicKey,
            chainCode: derivedChainCode,
            depth: depth + 1,
            parentFingerprint: publicKey.sha256Ripemd160.prefix(4),
            childNumber: index
        )
    }
    
    /// This function performs CKDpub((Kpar, cpar), i) → (Ki, ci) to compute a child extended public key from the parent extended public key.
    ///  It is only defined for non-hardened child keys. `secp256k1` only
    public func derivePublicKey(path derivationPath: DerivationPath) throws -> ExtendedPublicKey {
        var key: ExtendedPublicKey = self
        
        for node in derivationPath.nodes {
            key = try key.derivePublicKey(node: node)
        }
        
        return key
    }
}

// MARK: - ExtendedKeySerializable

extension ExtendedPublicKey: ExtendedKeySerializable {
    public init(from extendedKeyString: String, networkType: NetworkType) throws {
        guard let data = extendedKeyString.base58CheckDecodedData else {
            throw ExtendedKeySerializationError.decodingFailed
        }

        guard data.count == ExtendedKeySerializer.Constants.dataLength else {
            throw ExtendedKeySerializationError.wrongLength
        }

        let decodedVersion = UInt32(data.prefix(4).toInt()!) // it's safe to force unwrap here, because of size

        let version = ExtendedKeySerializer.Version.public

        guard decodedVersion == version.getPrefix(for: networkType) else {
            throw ExtendedKeySerializationError.wrongVersion
        }

        let depth = data.dropFirst(4).prefix(1).toInt()! // it's safe to force unwrap here, because of size
        let parentFingerprint = data.dropFirst(5).prefix(4)
        let childNumber = UInt32(data.dropFirst(9).prefix(4).toInt()!) // it's safe to force unwrap here, because of size
        let chainCode = data.dropFirst(13).prefix(32)
        let compressedKey = data.suffix(33)

        guard let _ = try? Secp256k1Key(with: compressedKey) else {
            throw TangemSdkError.unsupportedCurve
        }

        try self.init(
            publicKey: compressedKey,
            chainCode: chainCode,
            depth: depth,
            parentFingerprint: parentFingerprint,
            childNumber: childNumber
        )
    }

    public func serialize(for networkType: NetworkType) throws -> String {
        guard let secpKey = try? Secp256k1Key(with: publicKey) else {
            throw TangemSdkError.unsupportedCurve
        }

        let compressedKey = try secpKey.compress()

        var data = Data(capacity: ExtendedKeySerializer.Constants.dataLength)

        let version = ExtendedKeySerializer.Version.public

        data += version.getPrefix(for: networkType).bytes4
        data += depth.byte
        data += parentFingerprint
        data += childNumber.bytes4
        data += chainCode
        data += compressedKey

        guard data.count == ExtendedKeySerializer.Constants.dataLength else {
            throw ExtendedKeySerializationError.wrongLength
        }

        let resultString = Array(data).base58CheckEncodedString
        return resultString
    }
}

// MARK: - Decodable

extension ExtendedPublicKey: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let publicKey = try container.decode(Data.self, forKey: .publicKey)
        let chainCode = try container.decode(Data.self, forKey: .chainCode)
        let depth = try container.decodeIfPresent(Int.self, forKey: .depth)
        let parentFingerprint = try container.decodeIfPresent(Data.self, forKey: .parentFingerprint)
        let childNumber = try container.decodeIfPresent(UInt32.self, forKey: .childNumber)

        if let depth, let parentFingerprint, let childNumber {
            try self.init(publicKey: publicKey,
                          chainCode: chainCode,
                          depth: depth,
                          parentFingerprint: parentFingerprint,
                          childNumber: childNumber)
            return
        }

        if depth == nil, parentFingerprint == nil, childNumber == nil {
            self.init(publicKey: publicKey, chainCode: chainCode)
            return
        }

        throw TangemSdkError.decodingFailed("Missing data in the ExtendedPublicKey")
    }
}
