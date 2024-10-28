//
//  ChangeFileSettingsTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Task for updating settings for files saved on card
public final class ChangeFileSettingsTask: CardSessionRunnable {
    private var changes: [(Int, FileVisibility)]
    
    public init(changes: [Int: FileVisibility]) {
        self.changes = changes.map { ($0.key, $0.value) }
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        changeFileSettings(session: session, completion: completion)
    }
    
    private func changeFileSettings(session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let changes = changes.popLast() else {
            completion(.success(SuccessResponse(cardId: session.environment.card?.cardId ?? "")))
            return
        }
        
        let command = ChangeFileSettingsCommand(fileIndex: changes.0, newPermissions: changes.1)
        command.run(in: session) { result in
            switch result {
            case .success:
                self.changeFileSettings(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
