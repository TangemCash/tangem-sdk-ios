//
//  ResponseApdu+Combine.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 04.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CoreNFC

extension ResponseApdu {
    func decryptPublisher(encryptionKey: Data?) -> AnyPublisher<ResponseApdu, TangemSdkError> {
        return Deferred {Future() { promise in
            do {
                let decrypted = try self.decrypt(encryptionKey: encryptionKey)
                promise(.success(decrypted))
            } catch {
                promise(.failure(error.toTangemSdkError()))
            }
        }}.eraseToAnyPublisher()
    }
}

extension CommandApdu {
    func encryptPublisher(encryptionMode: EncryptionMode, encryptionKey: Data?) -> AnyPublisher<CommandApdu, TangemSdkError> {
        return Deferred {Future() { promise in
            do {
                let encrypted = try self.encrypt(encryptionMode: encryptionMode, encryptionKey: encryptionKey)
                promise(.success(encrypted))
            } catch {
                promise(.failure(error.toTangemSdkError()))
            }
        }}.eraseToAnyPublisher()
    }
}

extension NFCISO7816Tag {
    func sendCommandPublisher(cApdu: CommandApdu) -> AnyPublisher<Result<ResponseApdu, TangemSdkError>, TangemSdkError> {
        return Deferred { Future() { promise in
            let requestDate = Date()
            
            guard let apdu = NFCISO7816APDU(data: cApdu.serialize()) else {
                promise(.failure(TangemSdkError.failedToBuildCommandApdu))
                return
            }
            
            self.sendCommand(apdu: apdu) { data, sw1, sw2, error in
                if let sdkError = error?.toTangemSdkError() {
                    Log.error(sdkError)
                    promise(.failure(sdkError))
                } else {
                    let dateDiff = Calendar.current.dateComponents([.nanosecond], from: requestDate, to: Date())
                    Log.command("Command execution time is: \((dateDiff.nanosecond ?? 0)/1000000) ms")
                    
                    let rApdu = ResponseApdu(data, sw1, sw2)
                    promise(.success(.success(rApdu)))
                }
            }
        }}.eraseToAnyPublisher()
    }
}

extension NFCTagReaderSession {
    func connectPublisher(tag: NFCTag) -> AnyPublisher<Void, TangemSdkError> {
        return Deferred { Future() { promise in
            self.connect(to: tag) { error in
                if let error = error {
                    promise(.failure(error.toTangemSdkError()))
                } else {
                    promise(.success(()))
                }
            }
        }}.eraseToAnyPublisher()
    }
}

public extension TangemSdk {
    /// Combine wrapper for `startSession` method.
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - accessCode: Access code that will be used for a card session initialization. If nil, Tangem SDK will handle it automatically.
    /// - Returns: `AnyPublisher<T.Response, TangemSdkError>`
    func startSessionPublisher<T: CardSessionRunnable>(with runnable: T,
                                                       cardId: String?,
                                                       initialMessage: Message? = nil,
                                                       accessCode: String? = nil) -> AnyPublisher<T.Response, TangemSdkError> {
        return Deferred { Future() {
            self.startSession(with: runnable, cardId: cardId, initialMessage: initialMessage, accessCode: accessCode, completion: $0)
        }}.eraseToAnyPublisher()
    }

    /// Combine wrapper for `startSession` method.
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - filter: Filters card to be read. Optional.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - accessCode: Access code that will be used for a card session initialization. If nil, Tangem SDK will handle it automatically.
    /// - Returns: `AnyPublisher<T.Response, TangemSdkError>`
    func startSessionPublisher<T: CardSessionRunnable>(with runnable: T,
                                                       filter: SessionFilter?,
                                                       initialMessage: Message? = nil,
                                                       accessCode: String? = nil) -> AnyPublisher<T.Response, TangemSdkError> {
        return Deferred { Future() {
            self.startSession(with: runnable, filter: filter, initialMessage: initialMessage, accessCode: accessCode, completion: $0)
        }}.eraseToAnyPublisher()
    }
}
