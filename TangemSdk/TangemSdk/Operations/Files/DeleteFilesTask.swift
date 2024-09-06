//
//  DeleteFilesTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Task for deleting files from card.
public final class DeleteFilesTask: CardSessionRunnable {
    private let indices: [Int]?
    private var deleteRunnable: DeleteAllFilesTask?
    
    /// Task for deleting files from card.
    /// - Parameters:
    ///   - indices: Optional array of indices that should be deleted. If not specified all files will be deleted from card
    public init(indices: [Int]?) {
        self.indices = indices?.sorted(by: <)
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        if let indices = self.indices {
            deleteFiles(indices: indices, session: session, completion: completion)
        } else {
            deleteAllFiles(session: session, completion: completion)
        }
    }
    
    private func deleteAllFiles(session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        self.deleteRunnable = DeleteAllFilesTask()
        deleteRunnable!.run(in: session, completion: completion)
    }
    
    private func deleteFiles(indices: [Int], session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let index = indices.last else {
            completion(.success(SuccessResponse(cardId: session.environment.card?.cardId ?? "")))
            return
        }
        
        let command = DeleteFileCommand(fileIndex: index)
        command.run(in: session) { result in
            switch result {
            case .success:
                self.deleteFiles(indices: indices.dropLast(), session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
