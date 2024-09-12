//
//  PreflightReadTask.swift
//  TangemSdk
//
//  Created by Andrew Son on 15/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Mode for preflight read task
/// - Note: Valid for cards with COS v.4 and higher. Older card will always read the card and the wallet info. `fullCardRead` will be used by default
public enum PreflightReadMode: Decodable, Equatable {
    /// No card will be read at session start. `SessionEnvironment.card` will be empty
    case none
    /// Read only card info without wallet info. COS 4+. Older card will always read card and wallet info
    case readCardOnly
    /// Read card info and all wallets. Used by default
    case fullCardRead
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let stringValue = try values.decode(String.self).lowercased()
        
        switch stringValue {
        case "none":
            self = .none
        case "readcardonly":
            self = .readCardOnly
        case "fullcardread":
            self = .fullCardRead
        default:
            throw TangemSdkError.decodingFailed("Failed to decode PreflightReadMode")
        }
    }
}

final class PreflightReadTask: CardSessionRunnable {
    private let readMode: PreflightReadMode
    private let preflightFilter: PreflightReadFilter?

    init(readMode: PreflightReadMode, filter: PreflightReadFilter?) {
        self.readMode = readMode
        self.preflightFilter = filter
    }
    
    deinit {
        Log.debug("PreflightReadTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        Log.debug("Run preflight read with mode: \(readMode)")
        ReadCommand().run(in: session) { result in
            switch result {
            case .success(let readResponse):
                do {
                    let permanentFilter = session.environment.config.filter
                    try permanentFilter.verifyCard(readResponse)

                    if session.environment.config.handleErrors {
                        try self.preflightFilter?.onCardRead(readResponse, environment: session.environment)
                    }

                } catch {
                    completion(.failure(.preflightFiltered(error)))
                    return
                }
                
                self.updateEnvironmentIfNeeded(for: readResponse, in: session)
                session.fetchAccessCodeIfNeeded()
                
                self.finalizeRead(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func finalizeRead(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if card.firmwareVersion < .multiwalletAvailable {

            do {
                try self.filterOnReadWalletsList(card: card, session)
            } catch {
                completion(.failure(.preflightFiltered(error)))
                return
            }

            completion(.success(card))
            return
        }
        
        switch readMode {
        case .fullCardRead:
            readWalletsList(in: session, completion: completion)
        case .readCardOnly, .none:
            completion(.success(card))
        }
    }
    
    private func readWalletsList(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        ReadWalletsListCommand().run(in: session) { result in
            switch result {
            case .success:
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }

                do {
                    try self.filterOnReadWalletsList(card: card, session)
                } catch {
                    completion(.failure(.preflightFiltered(error)))
                    return
                }

                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func filterOnReadWalletsList(card: Card, _ session: CardSession) throws {
        guard session.environment.config.handleErrors else {
            return
        }

        do {
            try self.preflightFilter?.onFullCardRead(card, environment: session.environment)
        } catch {
            throw TangemSdkError.preflightFiltered(error)
        }
    }

    private func updateEnvironmentIfNeeded(for card: Card, in session: CardSession) {
        if FirmwareVersion.visaRange.contains(card.firmwareVersion.doubleValue) {
            session.environment.config.cardIdDisplayFormat = .none
        }
    }
}
