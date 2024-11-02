//
//  Hash.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Hash

struct Hash: Equatable {
    let index: Int
    let data: Data
}

// MARK: - SignedHash

struct SignedHash: Comparable {
    let index: Int
    let data: Data
    let signature: Data

    static func < (lhs: SignedHash, rhs: SignedHash) -> Bool {
        lhs.index < rhs.index
    }
}

// MARK: - Chunk

struct Chunk: Equatable {
    let hashSize: Int
    let hashes: [Hash]
}

// MARK: - SignedChunk

struct SignedChunk {
    let signedHashes: [SignedHash]
}
