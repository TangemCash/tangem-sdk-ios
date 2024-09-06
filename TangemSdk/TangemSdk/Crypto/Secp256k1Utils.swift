//
//  Secp256k1Utils.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk_secp256k1

typealias Secp256k1SignatureComponents = (r: Data, s: Data, v: Data)

public final class Secp256k1Utils {
    private let context: OpaquePointer
    
    public init() {
        context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_NONE))
    }
    
    deinit {
        secp256k1_context_destroy(context)
    }
    
    /**
     * Extension function to sign a byte array with the `Secp256k1` elliptic curve cryptography.
     *
     * - Parameter key: Key to sign data
     * - Parameter data: Data to sign
     *
     * - Returns: Signed data
     */
    public func sign(_ data: Data, with key: Data) throws -> Data {
        var signature = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_sign(context, &signature, Array(data.getSha256()), Array(key), nil, nil) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to sign")
        }
        
        var signatureData = [Byte](repeating: 0, count: 64)
        _ = secp256k1_ecdsa_signature_serialize_compact(context, &signatureData, &signature)
        
        return Data(signatureData)
    }
    
    /// Generate private/public keypair with secp256k1.
    /// - Returns: `KeyPair` with  32-bytes length `private key` and  65-bytes length uncompressed `public key`
    public func generateKeyPair() throws -> KeyPair {
        let privateKey = try CryptoUtils.generateRandomBytes(count: 32)
        let publicKey = try createPublicKey(privateKey: privateKey, compressed: false)
        return KeyPair(privateKey: privateKey, publicKey: publicKey)
    }
    
    public func serializeDer(_ signature: Data) throws -> Data {
        var sig = try parseNormalize(signature)
        return try serializeDer(&sig)
    }
    
    public func sum(compressedPubKey1: Data, compressedPubKey2: Data) throws -> Data {
        var pubKey1 = try parsePublicKey(compressedPubKey1)
        var pubKey2 = try parsePublicKey(compressedPubKey2)
        var publicKeySecp = secp256k1_pubkey()
        var result: Int32 = 0
        
        withUnsafePointer(to: &pubKey1) { pointer1 in
            withUnsafePointer(to: &pubKey2) { pointer2 in
                var pubkeyPointers: [UnsafePointer<secp256k1_pubkey>?] = [pointer1, pointer2]
                
                result = secp256k1_ec_pubkey_combine(context, &publicKeySecp, &pubkeyPointers, 2)
            }
        }
        
        guard result == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to sum keys")
        }
        
        return try serializePublicKey(&publicKeySecp, compressed: true)
    }
    
    func compressKey(_ publicKey: Data) throws -> Data {
        if publicKey.count == 33 {
            return publicKey
        }
        
        var secpKey = try parsePublicKey(publicKey)
        return try serializePublicKey(&secpKey, compressed: true)
    }
    
    func decompressKey(_ publicKey: Data) throws -> Data {
        if publicKey.count == 65 {
            return publicKey
        }
        
        var secpKey = try parsePublicKey(publicKey)
        return try serializePublicKey(&secpKey, compressed: false)
    }
    
    func verifySignature(_ signature: inout secp256k1_ecdsa_signature, publicKey: Data, hash: Data) throws -> Bool {
        var pubKey = try parsePublicKey(publicKey)
        
        guard secp256k1_ecdsa_verify(context, &signature, hash.toBytes, &pubKey) == 1 else {
            return false
        }
        
        return true
    }

    func verifySchnorrSignature(_ signature: Data, publicKey: Data, hash: Data) throws -> Bool {
        var pubKey = try parseXOnlyPublicKey(publicKey)
        var sig = signature.toBytes

        guard secp256k1_schnorrsig_verify(context, &sig, hash.toBytes, hash.count, &pubKey) == 1 else {
            return false
        }

        return true
    }
    
    func createPublicKey(privateKey: Data, compressed: Bool) throws -> Data {
        let privateKey = privateKey.toBytes
        var publicKey = secp256k1_pubkey()
        
        guard secp256k1_ec_seckey_verify(context, privateKey) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to verify the private key")
        }
        
        guard secp256k1_ec_pubkey_create(context, &publicKey, privateKey) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to create the public key")
        }
        
        return try serializePublicKey(&publicKey, compressed: compressed)
    }

    func createXOnlyPublicKey(privateKey: Data) throws -> Data {
        let privateKey = privateKey.toBytes

        guard secp256k1_ec_seckey_verify(context, privateKey) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to verify the private key")
        }

        var publicKey = secp256k1_pubkey()

        guard secp256k1_ec_pubkey_create(context, &publicKey, privateKey) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to create the public key")
        }

        var xOnlyPublicKey = secp256k1_xonly_pubkey()

        guard secp256k1_xonly_pubkey_from_pubkey(context, &xOnlyPublicKey, nil, &publicKey) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to create the public key")
        }

        var serializedXOnlyPublicKey = Array(repeating: UInt8(0), count: 32)

        guard secp256k1_xonly_pubkey_serialize(context, &serializedXOnlyPublicKey, &xOnlyPublicKey) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to create the public key")
        }

        return Data(serializedXOnlyPublicKey)
    }

    func isPrivateKeyValid(_ privateKey: Data) -> Bool {
        guard !privateKey.isEmpty else { return false }

        let privateKey = privateKey.toBytes
        return secp256k1_ec_seckey_verify(context, privateKey) == 1
    }
    
    func serializeDer(_ signature: inout secp256k1_ecdsa_signature) throws -> Data {
        var length: Int = 128
        var der = [UInt8].init(repeating: UInt8(0x0), count: Int(length))
        guard secp256k1_ecdsa_signature_serialize_der(context, &der, &length, &signature) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to serialize the signature")
        }
        
        return Data(der[0..<Int(length)])
    }
    
    func unmarshalSignature(_ signature: inout secp256k1_ecdsa_signature, publicKey: Data, hash: Data) throws -> Secp256k1SignatureComponents {
        guard hash.count == 32 else { throw TangemSdkError.cryptoUtilsError("Hash size must be 32 bytes length") }
        
        guard try verifySignature(&signature, publicKey: publicKey, hash: hash) else {
            throw TangemSdkError.cryptoUtilsError("Failed to verify the signature")
        }
        
        let isCompressed = publicKey.count == 33
        
        let serializedSig = try serializeSignature(&signature)
        var recoveredSignature: Data? = nil
        
        for v in 27..<31 {
            var recoverableSignature = try parseRecoverableSignature(serializedSig, v: Int32(v))
            var recoveredRawKey = try recoverPublicKey(hash: hash, recoverableSignature: &recoverableSignature)
            let recoveredKey = try serializePublicKey(&recoveredRawKey, compressed: isCompressed)
            
            if recoveredKey == publicKey {
                recoveredSignature = serializedSig + [UInt8(v)]
                break
            }
        }
        
        guard let recovered = recoveredSignature, recovered.count == 65 else {
            throw TangemSdkError.cryptoUtilsError("Failed to recover the signature")
        }
        
        let r = Data(recovered[0..<32])
        let s = Data(recovered[32..<64])
        let v = Data([recovered[64]])
        return (r: r, s: s, v: v)
    }
    
    func serializePublicKey(_ publicKey: inout secp256k1_pubkey, compressed: Bool) throws -> Data {
        var keyLength = compressed ? 33 : 65
        var serializedPubkey = Array(repeating: UInt8(0), count: Int(keyLength))
        
        secp256k1_ec_pubkey_serialize(context,
                                      &serializedPubkey,
                                      &keyLength,
                                      &publicKey,
                                      UInt32(compressed ? SECP256K1_EC_COMPRESSED : SECP256K1_EC_UNCOMPRESSED))
        
        return Data(serializedPubkey)
    }
    
    func serializeSignature(_ signature: inout secp256k1_ecdsa_signature) throws -> Data {
        var serialized = [UInt8].init(repeating: UInt8(0x0), count: 64)
        secp256k1_ecdsa_signature_serialize_compact(context, &serialized, &signature)
        return Data(serialized)
    }

    /// returns x-only part of secret without hashing
    func getSharedSecret(privateKey: Data, publicKey: Data) throws -> Data {
        let privkey = privateKey.toBytes
        var pubkey = try parsePublicKey(publicKey)
        var sharedSecret = Array(repeating: UInt8(0), count: 32)
        guard secp256k1_ecdh(context, &sharedSecret, &pubkey, privkey, secp256k1_ecdh_tangem, nil) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to compute an EC Diffie-Hellman secret ")
        }
        return Data(sharedSecret)
    }
    
    func parsePublicKey(_ publicKey: Data) throws -> secp256k1_pubkey {
        var pubkey = secp256k1_pubkey()
        
        guard secp256k1_ec_pubkey_parse(context, &pubkey, publicKey.toBytes, publicKey.count) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse the key")
        }
        
        return pubkey
    }

    func recoverPublicKey(signatureCoponents: Secp256k1SignatureComponents, hash: Data) throws -> secp256k1_pubkey {
        guard let intV = Int32(hexData: signatureCoponents.v) else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse v")
        }

        var recoverableSignature = try parseRecoverableSignature(signatureCoponents.r + signatureCoponents.s, v: intV)
        return try recoverPublicKey(hash: hash, recoverableSignature: &recoverableSignature)
    }

    func parseXOnlyPublicKey(_ publicKey: Data) throws -> secp256k1_xonly_pubkey {
        var pubkey = secp256k1_xonly_pubkey()

        guard secp256k1_xonly_pubkey_parse(context, &pubkey, publicKey.toBytes) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse the key")
        }

        return pubkey
    }
    
    private func recoverPublicKey(hash: Data, recoverableSignature: inout secp256k1_ecdsa_recoverable_signature) throws -> secp256k1_pubkey {
        guard hash.count == 32 else { throw TangemSdkError.cryptoUtilsError("Hash size must be 32 bytes length") }
        
        var publicKey: secp256k1_pubkey = secp256k1_pubkey()
        let result = hash.withUnsafeBytes({ (hashRawBufferPointer: UnsafeRawBufferPointer) -> Int32? in
            if let hashRawPointer = hashRawBufferPointer.baseAddress, !hashRawBufferPointer.isEmpty {
                let hashPointer = hashRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafePointer(to: &recoverableSignature, { (signaturePointer:UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    withUnsafeMutablePointer(to: &publicKey, { (pubKeyPtr: UnsafeMutablePointer<secp256k1_pubkey>) -> Int32 in
                        return secp256k1_ecdsa_recover(context, pubKeyPtr, signaturePointer, hashPointer)
                    })
                })
            } else {
                return nil
            }
        })
        
        guard let res = result, res != 0 else {
            throw TangemSdkError.cryptoUtilsError("Failed to recover the public key")
        }
        
        return publicKey
    }
    
    private func serializeSignature(recoverableSignature: inout secp256k1_ecdsa_recoverable_signature) throws -> Data {
        var serializedSignature = Data(repeating: 0x00, count: 64)
        var v: Int32 = 0
        let result = serializedSignature.withUnsafeMutableBytes { (serSignatureRawBufferPointer: UnsafeMutableRawBufferPointer) -> Int32? in
            if let serSignatureRawPointer = serSignatureRawBufferPointer.baseAddress, !serSignatureRawBufferPointer.isEmpty {
                let serSignaturePointer = serSignatureRawPointer.assumingMemoryBound(to: UInt8.self)
                return withUnsafePointer(to: &recoverableSignature) { (signaturePointer:UnsafePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    withUnsafeMutablePointer(to: &v, { (vPtr: UnsafeMutablePointer<Int32>) -> Int32 in
                        let res = secp256k1_ecdsa_recoverable_signature_serialize_compact(context, serSignaturePointer, vPtr, signaturePointer)
                        return res
                    })
                }
            } else {
                return nil
            }
        }
        
        guard let res = result, res != 0 else {
            throw TangemSdkError.cryptoUtilsError("Failed to serialize the signature")
        }
        
        if (v == 0 || v == 27 || v == 31 || v == 35) {
            serializedSignature.append(0x1b)
        } else if (v == 1 || v == 28 || v == 32 || v == 36) {
            serializedSignature.append(0x1c)
        } else {
            throw TangemSdkError.cryptoUtilsError("Failed to serialize the signature")
        }
        
        return Data(serializedSignature)
    }
    
    func normalizeSignature(_ signature: Data) throws -> Data {
        var parsed = try parseNormalize(signature)
        return try serializeSignature(&parsed)
    }
    
    func parseNormalize(_ signature: Data) throws -> secp256k1_ecdsa_signature {
        var sig = secp256k1_ecdsa_signature()
        
        guard secp256k1_ecdsa_signature_parse_compact(context, &sig, signature.toBytes) == 1 else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse the signature")
        }
        
        var normalizedSig = secp256k1_ecdsa_signature()
        _ = secp256k1_ecdsa_signature_normalize(context, &normalizedSig, &sig)
        return normalizedSig
    }
    
    private func parseRecoverableSignature(_ signature: Data, v: Int32) throws -> secp256k1_ecdsa_recoverable_signature {
        guard signature.count == 64 else { throw TangemSdkError.cryptoUtilsError("Invalid signature") }
        
        var recoverableSignature: secp256k1_ecdsa_recoverable_signature = secp256k1_ecdsa_recoverable_signature()
        
        var v = v
        if v >= 27 && v <= 30 {
            v -= 27
        } else if v >= 31 && v <= 34 {
            v -= 31
        } else if v >= 35 && v <= 38 {
            v -= 35
        }
        
        let result = signature.withUnsafeBytes { (serRawBufferPtr: UnsafeRawBufferPointer) -> Int32? in
            if let serRawPtr = serRawBufferPtr.baseAddress, !serRawBufferPtr.isEmpty {
                let serPtr = serRawPtr.assumingMemoryBound(to: UInt8.self)
                return withUnsafeMutablePointer(to: &recoverableSignature, { (signaturePointer:UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>) -> Int32 in
                    let res = secp256k1_ecdsa_recoverable_signature_parse_compact(context, signaturePointer, serPtr, v)
                    return res
                })
            } else {
                return nil
            }
        }
        
        guard let res = result, res != 0 else {
            throw TangemSdkError.cryptoUtilsError("Failed to parse the recoverable signature")
        }
        
        return recoverableSignature
    }
}
