//
//  ChunkHashesTests.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 31.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//


import Foundation
import XCTest
@testable import TangemSdk

class ChunkHashesTests: XCTestCase {
    func testSingleHashChunk() {
        let testData = ["f1642bb080e1f320924dde7238c1c5f8"]

        let hashes = testData.map { Data(hexString: $0) }
        let util = ChunkHashesUtil()

        let chunks = util.chunkHashes(hashes)
        XCTAssertEqual(chunks.count, 1)

        let expectedChunk = Chunk(hashSize: 16, hashes: [Hash(index: 0, data: hashes[0])])
        XCTAssertEqual(chunks, [expectedChunk])
    }

    func testMultipleHashesChunk() {
        let testData = [
            "f1642bb080e1f320924dde7238c1c5f8",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f8",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f8",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f0",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f1",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f2",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f3",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f4",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f5",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f6",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f7",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f9",
            "f1642bb080e1f320924dde7238c1c5f8",
            "f1642bb080e1f320924dde7238c1c5f8aa",
            "f1642bb080e1f320924dde7238c1c5f8ab",
        ]

        let hashes = testData.map { Data(hexString: $0) }
        let util = ChunkHashesUtil()

        let chunks = util.chunkHashes(hashes)
        XCTAssertEqual(chunks.count, 4)

        let expectedChunks = [
            Chunk(
                hashSize: 16,
                hashes: [
                    Hash(index: 0, data: hashes[0]),
                    Hash(index: 12, data: hashes[12])
                ]
            ),
            Chunk(
                hashSize: 17,
                hashes: [
                    Hash(index: 13, data: hashes[13]),
                    Hash(index: 14, data: hashes[14])
                ]
            ),
            Chunk(
                hashSize: 32,
                hashes: [
                    Hash(index: 1, data: hashes[1]),
                    Hash(index: 2, data: hashes[2]),
                    Hash(index: 3, data: hashes[3]),
                    Hash(index: 4, data: hashes[4]),
                    Hash(index: 5, data: hashes[5]),
                    Hash(index: 6, data: hashes[6]),
                    Hash(index: 7, data: hashes[7]),
                    Hash(index: 8, data: hashes[8]),
                    Hash(index: 9, data: hashes[9]),
                    Hash(index: 10, data: hashes[10]),
                ]
            ),
            Chunk(
                hashSize: 32,
                hashes: [
                    Hash(index: 11, data: hashes[11])
                ]
            )
        ]

        XCTAssertEqual(chunks.sorted(by: { $0.hashSize < $1.hashSize }), expectedChunks.sorted(by: { $0.hashSize < $1.hashSize }))
    }

    func testStrictSignaturesOrder() throws {
        let testHashesData = [
            "f1642bb080e1f320924dde7238c1c5f8",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f8",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f8",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f0",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f1",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f2",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f3",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f4",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f5",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f6",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f7",
            "f1642bb080e1f320924dde7238c1c5f8f1642bb080e1f320924dde7238c1c5f9",
            "f1642bb080e1f320924dde7238c1c5f8",
            "f1642bb080e1f320924dde7238c1c5f8aa",
            "f1642bb080e1f320924dde7238c1c5f8ab",
        ]

        let testSignaturesData = [
            "0001",
            "0002",
            "0003",
            "0004",
            "0005",
            "0006",
            "0007",
            "0008",
            "0009",
            "0010",
            "0011",
            "0012",
            "0013",
            "0014",
            "0015",
        ]

        let hashes = testHashesData.map { Data(hexString: $0) }
        let expectedSignatures = testSignaturesData.map { Data(hexString: $0) }

        var container = ChunkedHashesContainer(hashes: hashes)

        for _ in 0..<container.chunksCount {
            let chunk = try container.getCurrentChunk()

            let signedHashes = chunk.hashes.map {
                SignedHash(
                    index: $0.index,
                    data: $0.data,
                    signature: expectedSignatures[$0.index]
                )
            }
            container.addSignedChunk(SignedChunk(signedHashes: signedHashes))
        }

        let signatures = container.getSignatures()
        XCTAssertEqual(signatures, expectedSignatures)
    }
}
