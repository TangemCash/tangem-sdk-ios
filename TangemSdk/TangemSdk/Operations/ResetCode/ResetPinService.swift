//
//  ResetPinService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public class ResetPinService {
    public var currentState: State { _currentState.value }
    public var currentStatePublisher: AnyPublisher<State, Never> { _currentState.eraseToAnyPublisher() }

    public private(set) var error: TangemSdkError? = nil
    
    private var session: CardSession?
    private let config: Config
    private var repo: ResetPinRepo = .init()
    private var currentCommand: AnyObject? = nil
    private var _currentState: CurrentValueSubject<State, Never> = .init(.needCode)

    public init(config: Config) {
        self.config = config
    }
    
    deinit {
        Log.debug("ResetPinService deinit")
    }
    
    public func setAccessCode(_ code: String) throws {
        repo.accessCode = nil
        let code = code.trim()
        
        if config.handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.accessCodeRequired
            }
            
            if code == UserCodeType.accessCode.defaultValue {
                throw TangemSdkError.accessCodeCannotBeDefault
            }
            
            if code.count < UserCodeType.minLength {
                throw TangemSdkError.accessCodeTooShort
            }
        }
        
        repo.accessCode = code.sha256()
        
        if currentState == .needCode {
            _currentState.value = currentState.next()
        }
    }
    
    public func setPasscode(_ code: String) throws {
        repo.passcode = nil
        let code = code.trim()
        
        if config.handleErrors {
            guard !code.isEmpty else {
                throw TangemSdkError.passcodeRequired
            }
            
            if code == UserCodeType.passcode.defaultValue {
                throw TangemSdkError.passcodeCannotBeDefault
            }
            
            if code.count < UserCodeType.minLength {
                throw TangemSdkError.passcodeTooShort
            }
        }

        repo.passcode = code.sha256()

        if currentState == .needCode {
            _currentState.value = currentState.next()
        }
    }
    
    public func proceed(with resetCardId: String? = nil) {
        switch currentState {
        case .needScanResetCard:
            scanResetPinCard(resetCardId: resetCardId, handleCompletion)
        case .needScanConfirmationCard:
            scanConfirmationCard(handleCompletion)
        case .needWriteResetCard:
            writeResetPinCard(handleCompletion)
        case .finished, .needCode:
            break
        }
    }
    
    private func handleCompletion(_ result: Result<Void, TangemSdkError>) -> Void {
        switch result {
        case .success:
            _currentState.value = currentState.next()
        case .failure(let error):
            self.error = error
        }
    }
    
    private func scanResetPinCard(resetCardId: String?, _ completion: @escaping CompletionResult<Void>) {
        let userCodeType: UserCodeType
        if repo.accessCode != nil {
            userCodeType = .accessCode
        } else if repo.passcode != nil {
            userCodeType = .passcode
        } else {
            fatalError("Scan card called without the code specified")
        }
        
        self.session = TangemSdk().makeSession(with: config,
                                               filter: .init(from: resetCardId),
                                               initialMessage: Message(header: "reset_codes_scan_first_card".localized([userCodeType.name.lowercased()])))

        let command = GetResetPinTokenCommand()
        currentCommand = command
        
        session!.start(with: command) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                self.repo.resetPinCard = response
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            self.currentCommand = nil
        }
    }
    
    private func scanConfirmationCard(_ completion: @escaping CompletionResult<Void>) {
        guard let resetPinCard = repo.resetPinCard else {
            completion(.failure(.unknownError))
            return
        }
        
        self.session = TangemSdk().makeSession(with: config,
                                               filter: nil,
                                               initialMessage: Message(header: "reset_codes_scan_confirmation_card".localized))

        let command = SignResetPinTokenCommand(resetPinCard: resetPinCard)
        currentCommand = command

        session!.start(with: command) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                self.repo.confirmationCard = response
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            self.currentCommand = nil
        }
    }
    
    private func writeResetPinCard(_ completion: @escaping CompletionResult<Void>) {
        guard let resetPinCard = repo.resetPinCard else {
            completion(.failure(.unknownError))
            return
        }
        
        guard let confirmationCard = repo.confirmationCard else {
            completion(.failure(.unknownError))
            return
        }
        
        var accessCode = repo.accessCode
        var passcode = repo.passcode
        
        if config.handleErrors {
            if !resetPinCard.isAccessCodeSet {
                accessCode = UserCodeType.accessCode.defaultValue.sha256()
            }
            
            if !resetPinCard.isPasscodeSet {
                passcode = UserCodeType.passcode.defaultValue.sha256()
            }
        }
        
        guard let accessCodeUnwrapped = accessCode else {
            completion(.failure(.accessCodeRequired))
            return
        }
        
        guard let passcodeUnwrapped = passcode else {
            completion(.failure(.passcodeRequired))
            return
        }
        
        self.session = TangemSdk().makeSession(with: config,
                                               filter: .cardId(resetPinCard.cardId),
                                               initialMessage: Message(header: "reset_codes_scan_to_reset".localized))

        let command = ResetPinTask(confirmationCard: confirmationCard, accessCode: accessCodeUnwrapped, passcode: passcodeUnwrapped)
        currentCommand = command

        session!.start(with: command) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }

            self.currentCommand = nil
        }
    }
}

extension ResetPinService {
    class ResetPinRepo {
        var confirmationCard: ConfirmationCard? = nil
        var resetPinCard: ResetPinCard? = nil
        var accessCode: Data?
        var passcode: Data?
    }
    
    public enum State: Equatable, CaseIterable {
        case needCode
        case needScanResetCard
        case needScanConfirmationCard
        case needWriteResetCard
        case finished
        
        var messageTitle: String {
            switch self {
            case .finished: return "common_success".localized
            case .needScanConfirmationCard:
                return "reset_codes_message_title_backup".localized
            case .needScanResetCard, .needWriteResetCard:
                return "reset_codes_message_title_restore".localized
            case .needCode:
                return ""
            }
        }
        
        var messageBody: String {
            switch self {
            case .finished: return "reset_codes_success_message".localized
            case .needScanConfirmationCard:
                return "reset_codes_message_body_backup".localized
            case .needScanResetCard:
                return "reset_codes_message_body_restore".localized
            case .needWriteResetCard:
                return "reset_codes_message_body_restore_final".localized
            case .needCode:
                return ""
            }
        }
        
        var cardType: CardType {
            switch self {
            case .needCode, .needScanResetCard, .needWriteResetCard, .finished:
                return .origin
            case .needScanConfirmationCard:
                return .backup
            }
        }
    }
}

enum CardType {
    case origin
    case backup
    
    var topIndex: Int {
        switch self {
        case .origin:
            return 0
        case .backup:
            return 1
        }
    }
    
    var bottomIndex: Int {
        switch self {
        case .origin:
            return 1
        case .backup:
            return 0
        }
    }
}

struct ResetPinCard {
    let cardId: String
    let backupKey: Data
    let attestSignature: Data
    let token: Data
    let isAccessCodeSet: Bool
    let isPasscodeSet: Bool
}

struct ConfirmationCard {
    let cardId: String
    let backupKey: Data
    let salt: Data
    let authorizeSignature: Data
}
