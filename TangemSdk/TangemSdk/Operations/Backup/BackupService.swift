//
//  BackupService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public class BackupService: ObservableObject {
    public static let maxBackupCardsCount = 2
    
    @Published public private(set) var currentState: State = .preparing
    
    public var canAddBackupCards: Bool {
        addedBackupCardsCount < BackupService.maxBackupCardsCount
        &&  repo.data.primaryCard?.linkingKey != nil
    }
    
    public var hasIncompletedBackup: Bool {
        switch currentState {
        case .finalizingPrimaryCard, .finalizingBackupCard:
            return true
        default:
            return false
        }
    }
    
    public var addedBackupCardsCount: Int { repo.data.backupCards.count }
    public var canProceed: Bool { currentState != .preparing && currentState != .finished }
    public var accessCodeIsSet: Bool { repo.data.accessCode != nil }
    public var passcodeIsSet: Bool { repo.data.passcode != nil }
    public var primaryCardIsSet: Bool { repo.data.primaryCard != nil }
    public var primaryCardId: String? { repo.data.primaryCard?.cardId }
    public var backupCardIds: [String] { repo.data.backupCards.map {$0.cardId} }
    public var allCardIds: [String] { [primaryCardId].compactMap { $0 } + backupCardIds }
    
    /// Perform additional compatibility checks while adding backup cards. Change this setting only if you understand what you do.
    public var skipCompatibilityChecks: Bool = false
    
    private let sdk: TangemSdk
    private var repo: BackupRepo = .init()
    private var currentCommand: AnyObject? = nil
    private var handleErrors: Bool { sdk.config.handleErrors }
    
    public init(sdk: TangemSdk) {
        self.sdk = sdk
        self.updateState()
    }
    
    deinit {
        Log.debug("BackupService deinit")
    }
    
    public func discardIncompletedBackup() {
        repo.reset()
        updateState()
    }
    
    public func addBackupCard(completion: @escaping CompletionResult<Void>) {
        guard let primaryCard = repo.data.primaryCard else {
            completion(.failure(.missingPrimaryCard))
            return
        }
        
        if handleErrors {
            guard addedBackupCardsCount < BackupService.maxBackupCardsCount else {
                completion(.failure(.tooMuchBackupCards))
                return
            }
        }
        
        readBackupCard(primaryCard, completion: completion)
    }
    
    public func setAccessCode(_ code: String) throws {
        repo.data.accessCode = nil
        let code = code.trim()
        
        if handleErrors {
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
        
        guard currentState == .preparing || currentState == .finalizingPrimaryCard else {
            throw TangemSdkError.accessCodeCannotBeChanged
        }
        
        repo.data.accessCode = code.sha256()
        updateState()
    }
    
    public func setPasscode(_ code: String) throws {
        repo.data.passcode = nil
        let code = code.trim()
        
        if handleErrors {
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
        
        guard currentState == .preparing || currentState == .finalizingPrimaryCard else {
            throw TangemSdkError.passcodeCannotBeChanged
        }
        
        repo.data.passcode = code.sha256()
        updateState()
    }
    
    public func proceedBackup(completion: @escaping CompletionResult<Card>) {
        switch currentState {
        case .finalizingPrimaryCard:
            handleFinalizePrimaryCard() {
                self.handleCompletion($0, completion: completion)
            }
        case .finalizingBackupCard(let index):
            handleWriteBackupCard(index: index) {
                self.handleCompletion($0, completion: completion)
            }
        case .preparing, .finished:
            completion(.failure(TangemSdkError.backupServiceInvalidState))
        }
    }
    
    public func setPrimaryCard(_ primaryCard: PrimaryCard) {
        repo.data.primaryCard = primaryCard
        updateState()
    }
    
    public func readPrimaryCard(cardId: String? = nil, completion: @escaping CompletionResult<Void>) {
        let initialMessage = cardId.map {
            let formattedCardId = CardIdFormatter(style: .lastMasked(4)).string(from: $0)
            return  Message(header: nil,
                            body: "backup_prepare_primary_card_message_format".localized(formattedCardId)) }
        ?? Message(header: "backup_prepare_primary_card_message".localized)
         
        let command = StartPrimaryCardLinkingTask()
        currentCommand = command
        sdk.startSession(with: command,
                         cardId: cardId,
                         initialMessage: initialMessage
        ) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.setPrimaryCard(response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
            self.currentCommand = nil
        }
    }
    
    private func handleCompletion(_ result: Result<Card, TangemSdkError>, completion: @escaping CompletionResult<Card>) -> Void {
        switch result {
        case .success(let card):
            updateState()
            completion(.success(card))
        case .failure(let error):
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    @discardableResult
    private func updateState() -> State {
        if repo.data.accessCode == nil
            || repo.data.primaryCard == nil
            || repo.data.backupCards.isEmpty {
            currentState = .preparing
        } else if repo.data.attestSignature == nil || repo.data.backupData.isEmpty {
            currentState = .finalizingPrimaryCard
        } else if repo.data.finalizedBackupCardsCount < repo.data.backupCards.count {
            currentState = .finalizingBackupCard(index: repo.data.finalizedBackupCardsCount + 1)
        } else {
            currentState = .finished
            onBackupCompleted()
        }
        
        return currentState
    }
    
    private func addBackupCard(_ backupCard: BackupCard) {
        if let existingIndex = repo.data.backupCards.firstIndex(where: { $0.cardId == backupCard.cardId }) {
            repo.data.backupCards.remove(at: existingIndex)
        }
        
        repo.data.backupCards.append(backupCard)
        updateState()
    }
    
    private func readBackupCard(_ primaryCard: PrimaryCard, completion: @escaping CompletionResult<Void>) {
        let command = StartBackupCardLinkingTask(primaryCard: primaryCard,
                                                 addedBackupCards: repo.data.backupCards.map { $0.cardId },
                                                 skipCompatibilityChecks: skipCompatibilityChecks)
        currentCommand = command
        
        sdk.startSession(with: command,
                         initialMessage: Message(header: nil,
                                                 body: "backup_add_backup_card_message".localized)) {[weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.addBackupCard(response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
            self.currentCommand = nil
        }
    }
    
    private func handleFinalizePrimaryCard(completion: @escaping CompletionResult<Card>) {
        do {
            if handleErrors {
                if repo.data.accessCode == nil && repo.data.passcode == nil {
                    throw TangemSdkError.accessCodeOrPasscodeRequired
                }
            }
            
            let accessCode = repo.data.accessCode ?? UserCodeType.accessCode.defaultValue.sha256()
            let passcode = repo.data.passcode ?? UserCodeType.passcode.defaultValue.sha256()
            
            guard let primaryCard = repo.data.primaryCard else {
                throw TangemSdkError.missingPrimaryCard
            }
            
            if handleErrors {
                guard !repo.data.backupCards.isEmpty else {
                    throw TangemSdkError.emptyBackupCards
                }
                
                guard repo.data.backupCards.count < 3 else {
                    throw TangemSdkError.tooMuchBackupCards
                }
            }
            
            let task = FinalizePrimaryCardTask(backupCards: repo.data.backupCards,
                                              accessCode: accessCode,
                                              passcode: passcode,
                                              readBackupStartIndex: repo.data.backupData.count,
                                              attestSignature: repo.data.attestSignature,
                                              onLink: { self.repo.data.attestSignature = $0 },
                                              onRead: { self.repo.data.backupData[$0.0] = $0.1 })
            
            let formattedCardId = CardIdFormatter(style: .lastMasked(4)).string(from: primaryCard.cardId)
            
            sdk.startSession(with: task,
                             cardId: primaryCard.cardId,
                             initialMessage: Message(header: nil,
                                                     body: "backup_finalize_primary_card_message_format".localized(formattedCardId)),
                             completion: completion)
            
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    private func handleWriteBackupCard(index: Int, completion: @escaping CompletionResult<Card>) {
        do {
            if handleErrors {
                if repo.data.accessCode == nil && repo.data.passcode == nil {
                    throw TangemSdkError.accessCodeOrPasscodeRequired
                }
            }
            
            let accessCode = repo.data.accessCode ?? UserCodeType.accessCode.defaultValue.sha256()
            let passcode = repo.data.passcode ?? UserCodeType.passcode.defaultValue.sha256()
            
            guard let attestSignature = repo.data.attestSignature else {
                throw TangemSdkError.missingPrimaryAttestSignature
            }
            
            guard let primaryCard = repo.data.primaryCard else {
                throw TangemSdkError.missingPrimaryCard
            }
            
            let cardIndex = index - 1
            
            guard cardIndex < repo.data.backupCards.count else {
                throw TangemSdkError.noBackupCardForIndex
            }
            
            if handleErrors {
                guard repo.data.backupCards.count < 3 else {
                    throw TangemSdkError.tooMuchBackupCards
                }
            }
            
            let backupCard = repo.data.backupCards[cardIndex]
            
            guard let backupData = repo.data.backupData[backupCard.cardId] else {
                throw TangemSdkError.noBackupDataForCard
            }
            
            let command = FinalizeBackupCardTask(primaryCard: primaryCard,
                                                 backupCards: repo.data.backupCards,
                                                 backupData: backupData,
                                                 attestSignature: attestSignature,
                                                 accessCode: accessCode,
                                                 passcode: passcode)
            
            let formattedCardId = CardIdFormatter(style: .lastMasked(4)).string(from: backupCard.cardId)
            
            sdk.startSession(with: command,
                             cardId: backupCard.cardId,
                             initialMessage: Message(header: nil,
                                                     body: "backup_finalize_backup_card_message_format".localized(formattedCardId))) { result in
                switch result {
                case .success(let card):
                    self.repo.data.finalizedBackupCardsCount += 1
                    completion(.success(card))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    private func onBackupCompleted() {
        repo.reset()
    }
}

@available(iOS 13.0, *)
extension BackupService {
    public enum State: Equatable {
        case preparing
        case finalizingPrimaryCard
        case finalizingBackupCard(index: Int)
        case finished
    }
}

@available(iOS 13.0, *)
public struct RawPrimaryCard {
    public let cardId: String
    public let cardPublicKey: Data
    public let linkingKey: Data
    
    //For compatibility check with backup card
    public let existingWalletsCount: Int
    public let isHDWalletAllowed: Bool
    public let issuer: Card.Issuer
    public let walletCurves: [EllipticCurve]
    public let batchId: String? //for compatibility with interrupted backups
}

@available(iOS 13.0, *)
public struct PrimaryCard: Codable, CertificateProvider {
    public let cardId: String
    public let cardPublicKey: Data
    public let linkingKey: Data
    public let issuerSignature: Data
    
    //For compatibility check with backup card
    public let existingWalletsCount: Int
    public let isHDWalletAllowed: Bool
    public let issuer: Card.Issuer
    public let walletCurves: [EllipticCurve]
    public let batchId: String? //for compatibility with interrupted backups
    
    public init(_ rawPrimaryCard: RawPrimaryCard, issuerSignature: Data) {
        self.cardId = rawPrimaryCard.cardId
        self.cardPublicKey = rawPrimaryCard.cardPublicKey
        self.linkingKey = rawPrimaryCard.linkingKey
        self.issuerSignature = issuerSignature
        self.existingWalletsCount = rawPrimaryCard.existingWalletsCount
        self.isHDWalletAllowed = rawPrimaryCard.isHDWalletAllowed
        self.issuer = rawPrimaryCard.issuer
        self.walletCurves = rawPrimaryCard.walletCurves
        self.batchId = rawPrimaryCard.batchId
    }
}

@available(iOS 13.0, *)
struct RawBackupCard {
    let cardId: String
    let cardPublicKey: Data
    let linkingKey: Data
    let attestSignature: Data
}

@available(iOS 13.0, *)
struct BackupCard: Codable, CertificateProvider {
    let cardId: String
    let cardPublicKey: Data
    let linkingKey: Data
    let attestSignature: Data
    let issuerSignature: Data
    
    init(_ rawCard: RawBackupCard, issuerSignature: Data) {
        self.cardId = rawCard.cardId
        self.cardPublicKey = rawCard.cardPublicKey
        self.linkingKey = rawCard.linkingKey
        self.attestSignature = rawCard.attestSignature
        self.issuerSignature = issuerSignature
    }
}

struct EncryptedBackupData: Codable {
    let data: Data
    let salt: Data
}

@available(iOS 13.0, *)
struct BackupServiceData: Codable {
    var accessCode: Data? = nil
    var passcode: Data? = nil
    var primaryCard: PrimaryCard? = nil
    var attestSignature: Data? = nil
    var backupCards: [BackupCard] = []
    var backupData: [String:[EncryptedBackupData]] = [:]
    var finalizedBackupCardsCount: Int = 0
    
    var shouldSave: Bool {
         attestSignature != nil || !backupData.isEmpty
    }
}

@available(iOS 13.0, *)
class BackupRepo {
    private let storage = SecureStorage()
    private var isFetching: Bool = false
    
    var data: BackupServiceData = .init() {
        didSet {
            try? save()
        }
    }
   
    init () {
        try? fetch()
    }
    
    func reset() {
        try? storage.delete(.backupData)
        data = .init()
    }
    
    private func save() throws {
        guard !isFetching && data.shouldSave else { return }
        
        let encoded = try JSONEncoder().encode(data)
        try storage.store(encoded, forKey: .backupData)
    }
    
    private func fetch() throws {
        self.isFetching = true
        defer { self.isFetching = false }
        
        if let savedData = try storage.get(.backupData) {
            self.data = try JSONDecoder().decode(BackupServiceData.self, from: savedData)
        }
    }
}

@available(iOS 13.0, *)
protocol CertificateProvider {
    var cardPublicKey: Data { get }
    var issuerSignature: Data { get }
    
    func generateCertificate() throws -> Data
}

@available(iOS 13.0, *)
extension CertificateProvider {
    func generateCertificate() throws -> Data {
        return try TlvBuilder()
            .append(.cardPublicKey, value: cardPublicKey)
            .append(.issuerDataSignature, value: issuerSignature)
            .serialize()
    }
}
