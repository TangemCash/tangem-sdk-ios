//
//  RunnablesTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 30.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

typealias RunnablesTaskResponse = [JSONRPCResponse]

final class RunnablesTask: CardSessionRunnable {
    private let runnables: [AnyJSONRPCRunnable]
    private var responses: RunnablesTaskResponse = .init()
    
    init(runnables: [AnyJSONRPCRunnable]) {
        self.runnables = runnables
    }
    
    deinit {
        Log.debug("RunnablesTask deinit")
    }
    
    func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        prepare(session, with: 0, completion: completion)
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<RunnablesTaskResponse>) {
        run(in: session, with: 0, completion: completion)
    }
    
    private func prepare(_ session: CardSession, with index: Int, completion: @escaping CompletionResult<Void>) {
        if index >= runnables.count {
            completion(.success(()))
            return
        }
        
        let runnable = runnables[index]
        runnable.prepare(session) { result in
            switch result {
            case .success:
                self.prepare(session, with: index + 1, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
           
        }
    }
    
    private func run(in session: CardSession, with index: Int, completion: @escaping CompletionResult<RunnablesTaskResponse>) {
        if index >= runnables.count {
            completion(.success(responses))
            return
        }
        
        let runnable = runnables[index]
        runnable.run(in: session) {
            let jsonResponse = $0.toJsonResponse(id: runnable.id)
            self.responses.append(jsonResponse)
            self.run(in: session, with: index + 1, completion: completion)
        }
    }
}
