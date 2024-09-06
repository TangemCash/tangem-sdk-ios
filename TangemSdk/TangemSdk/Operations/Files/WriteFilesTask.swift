//
//  WriteFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Response for `WriteFilesTask`.
/// - Parameters:
///   - cardId: CID, Unique Tangem card ID number
///   - fileIndices: Indicies of created files
public struct WriteFilesResponse: JSONStringConvertible {
    public let cardId: String
    public let filesIndices: [Int]
}

/// This task allows to write multiple files to a card.
/// There are two secure ways to write files.
/// 1. Data can be signed by owner (the one specified on card during personalization)
/// 2. Data can be protected by user code.  In this case,  user code is required for the command.
public final class WriteFilesTask: CardSessionRunnable {
    private let files: [FileToWrite]
    private var savedFilesIndices: [Int] = []
    
    /// Default initializer
    /// - Parameter files: Array of files to write
    public init(files: [FileToWrite]) {
        self.files = files
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
        if files.isEmpty {
            completion(.failure(.filesIsEmpty))
            return
        }
        
        writeFile(index: 0, session: session, completion: completion)
    }
    
    private func writeFile(index: Int, session: CardSession, completion: @escaping CompletionResult<WriteFilesResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.cardError))
            return
        }
        
        guard index < files.count else {
            completion(.success(.init(cardId: card.cardId, filesIndices: savedFilesIndices)))
            return
        }

        WriteFileCommand(files[index])
            .run(in: session) { result in
                switch result {
                case .success(let response):
                    self.savedFilesIndices.append(response.fileIndex ?? 0)
                    self.writeFile(index: index + 1, session: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
