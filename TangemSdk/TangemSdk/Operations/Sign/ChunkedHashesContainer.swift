//
//  ChunkedHashesContainer.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//


import Foundation

struct ChunkedHashesContainer {
    var isEmpty: Bool { chunks.isEmpty }
    let chunksCount: Int

    private(set) var currentChunkIndex: Int = 0

    private let chunks: [Chunk]
    private var signedChunks: [SignedChunk] = []

    init(hashes: [Data]) {
        self.chunks = ChunkHashesUtil().chunkHashes(hashes)
        self.chunksCount = chunks.count
    }

    func getCurrentChunk() throws -> Chunk {
        guard currentChunkIndex < chunks.count else {
            throw ChunkedHashesContainerError.processingError
        }

        return chunks[currentChunkIndex]
    }

    mutating func addSignedChunk(_ signedChunk: SignedChunk) {
        signedChunks.append(signedChunk)
        currentChunkIndex += 1
    }

    func getSignatures() -> [Data] {
        let signedHashes = signedChunks.flatMap { $0.signedHashes }.sorted()
        let signatures = signedHashes.map { $0.signature }
        return signatures
    }
}

// MARK: - ChunkedHashesContainerError

enum ChunkedHashesContainerError: Error {
    case processingError
}

