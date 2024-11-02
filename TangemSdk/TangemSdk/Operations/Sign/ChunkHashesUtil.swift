//
//  ChunkHashesUtil.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ChunkHashesUtil {
    func chunkHashes(_ hashes: [Data]) -> [Chunk] {
        let hashes = hashes.enumerated().map { Hash(index: $0.offset, data: $0.element) }
        let hashesBySize = Dictionary(grouping: hashes, by: { $0.data.count })

        let chunks = hashesBySize.flatMap { hashesGroup in
            let hashSize = hashesGroup.key
            let chunkSize = getChunkSize(for: hashSize)

            let chunkedHashes = hashesGroup.value.chunked(into: chunkSize)
            let chunks = chunkedHashes.map { Chunk(hashSize: hashSize, hashes: $0) }

            return chunks
        }

        return chunks
    }

    func getChunkSize(for hashSize: Int) -> Int {
        /// These devices are not able to sign long hashes.
        if NFCUtils.isPoorNfcQualityDevice {
            return Constants.maxChunkSizePoorNfcQualityDevice
        }

        guard hashSize > 0 else {
            return Constants.maxChunkSize
        }

        let estimatedChunkSize = Constants.packageSize / hashSize
        let chunkSize = max(1, min(estimatedChunkSize, Constants.maxChunkSize))
        return chunkSize
    }
}

// MARK: -  Constants

private extension ChunkHashesUtil {
    enum Constants {
        /// The max answer is 1152 bytes (unencrypted) and 1120 (encrypted). The worst case is 8 hashes * 64 bytes for ed + 512 bytes of signatures + cardId, SignedHashes + TLV + SW is ok.
        static let packageSize = 512

        /// Card limitation
        static let maxChunkSize = 10

        /// Empirical value
        static let maxChunkSizePoorNfcQualityDevice = 2
    }
}
