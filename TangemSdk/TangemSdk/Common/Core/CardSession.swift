//
//  CardSession.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.03.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CommonCrypto

/// Allows interaction with Tangem cards. Should be open before sending commands
public class CardSession {
    enum CardSessionState {
        case inactive
        case active
    }
    /// Allows interaction with users and shows visual elements.
    public let viewDelegate: SessionViewDelegate
    
    var state: CardSessionState = .inactive

    /// Contains data relating to the current Tangem card. It is used in constructing all the commands,
    /// and commands can modify `SessionEnvironment`.
    var cardId: String? {
        switch filter {
        case .cardId(let cardId):
            return cardId
        default:
            return nil
        }
    }

    // initial environment to be able to reset a current one
    private var _environment: SessionEnvironment
    public internal(set) var environment: SessionEnvironment

    private let reader: CardReader
    private let jsonConverter: JSONRPCConverter
    private let initialMessage: Message?
    private var sendSubscription: [AnyCancellable] = []
    private var nfcReaderSubscriptions: [AnyCancellable] = []
    
    private var preflightReadMode: PreflightReadMode = .fullCardRead
    private var currentTag: NFCTagType = .none
    private var resetCodesController: ResetCodesController? = nil
    /// Allows access codes to be stored in a secure location
    private var accessCodeRepository: AccessCodeRepository? = nil
    private let filter: SessionFilter?

    private var defaultScanMessage: String {
        "view_delegate_scan_description_format".localized(environment.config.productType.localizedDescription)
    }

    private var shouldRequestBiometrics: Bool {
        guard let accessCodeRepository = self.accessCodeRepository else {
            return false
        }
        
        if let cardId = self.cardId {
            return accessCodeRepository.contains(cardId)
        }
        
        return !accessCodeRepository.isEmpty
    }
    
    /// Main initializer
    /// - Parameters:
    ///   - environment: Contains data relating to a Tangem card
    ///   - filter: Filters card to be read. Optional.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - cardReader: NFC-reader implementation
    ///   - viewDelegate: viewDelegate implementation
    ///   - jsonConverter: JSONRPCConverter
    ///   - accessCodeRepository: Optional AccessCodeRepository that saves access codes to Apple Keychain
    init(environment: SessionEnvironment,
         filter: SessionFilter? = nil,
         initialMessage: Message? = nil,
         cardReader: CardReader,
         viewDelegate: SessionViewDelegate,
         jsonConverter: JSONRPCConverter,
         accessCodeRepository: AccessCodeRepository?) {
        self.reader = cardReader
        self.viewDelegate = viewDelegate
        self._environment = environment
        self.environment = environment
        self.initialMessage = initialMessage
        self.filter = filter
        self.jsonConverter = jsonConverter
        self.accessCodeRepository = accessCodeRepository
    }
    
    deinit {
        Log.debug("Card session deinit")
    }
    
    // MARK: - Session start
    /// This metod starts a card session, performs preflight `Read` command,  invokes the `run ` method of `CardSessionRunnable` and closes the session.
    /// - Parameters:
    ///   - runnable: The CardSessionRunnable implemetation
    ///   - completion: Completion handler. `(Swift.Result<CardSessionRunnable.Response, TangemSdkError>) -> Void`
    public func start<T>(with runnable: T, completion: @escaping CompletionResult<T.Response>) where T : CardSessionRunnable {
        guard NFCUtils.isNFCAvailable else {
            Log.error(TangemSdkError.unsupportedDevice)
            completion(.failure(.unsupportedDevice))
            return
        }
        
        guard state == .inactive /*&& !reader.isSessionReady.value */ else {
            Log.error(TangemSdkError.busy)
            completion(.failure(.busy))
            return
        }
        
        Log.session("Start card session with runnable")
        
        prepareSession(for: runnable) { prepareResult in
            switch prepareResult {
            case .success:
                self.start() {[weak self] session, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        Log.error(error)
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    Log.session("Start runnable")
                    
                    runnable.run(in: self) {[weak self] result in
                        guard let self = self else { return }
                        
                        Log.session("Runnable completed")
                        switch result {
                        case .success(let runnableResponse):
                            self.stop(message: "nfc_alert_default_done".localized) {
                                completion(.success(runnableResponse))
                                
                                session.saveAccessCodeIfNeeded()
                            }
                        case .failure(let error):
                            Log.error(error)
                            self.stop(error: error) {
                                completion(.failure(error))
                            }
                        }
                    }
                }
            case .failure(let error):
                Log.error(error)
                self.stop(error: error) {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Session subscriptions
    /// Starts a card session and performs preflight `Read` command.
    /// - Parameter onSessionStarted: Delegate with the card session. Can contain error
    public func start(_ onSessionStarted: @escaping (CardSession, TangemSdkError?) -> Void) {
        guard NFCUtils.isNFCAvailable else {
            onSessionStarted(self, .unsupportedDevice)
            return
        }
        
        guard state == .inactive /*&& !reader.isSessionReady.value*/ else {
            onSessionStarted(self, .busy)
            return
        }
        
        Log.session("Start card session with delegate")
        state = .active
        
        reader.viewEventsPublisher //Subscription for reader's view events and invoke viewDelegate
            .dropFirst()
            .removeDuplicates()
            .sink(receiveValue: { [weak self] event in
                guard let self else { return }

                switch event {
                case .none:
                    break
                case .sessionStarted:
                    self.viewDelegate.sessionStarted()
                    self.viewDelegate.setState(.scan)
                case .sessionStopped:
                    self.viewDelegate.sessionStopped(completion: nil)
                case .tagConnected:
                    self.viewDelegate.tagConnected()
                    self.viewDelegate.setState(.default)
                case .tagLost:
                    self.viewDelegate.tagLost(message: defaultScanMessage)
                    self.viewDelegate.setState(.scan)
                }
            })
            .store(in: &nfcReaderSubscriptions)
        
        reader.tag //Subscription for handle tag lost events
            .dropFirst()
            .filter { $0 == .none }
            .sink(receiveCompletion: {_ in},
                  receiveValue: {[weak self] tag in
                self?.environment.encryptionKey = nil
            })
            .store(in: &nfcReaderSubscriptions)
        
        reader.tag //Subscription for session initialization and handling any error before session is activated
            .filter { $0 != .none }
            .first()
            .sink(receiveCompletion: { [weak self] readerCompletion in
                guard let self else { return }

                if case let .failure(error) = readerCompletion {
                    self.stop(error: error) {
                        onSessionStarted(self, error)
                    }
                }}, receiveValue: { [weak self] tag in
                    guard let self else { return }

                    if case .tag = tag, self.preflightReadMode != .none {
                        self.preflightCheck(onSessionStarted)
                    } else {
                        onSessionStarted(self, nil)
                    }
                })
            .store(in: &nfcReaderSubscriptions)
        
        reader.startSession(with: initialMessage?.alertMessage ?? defaultScanMessage)
    }
    
    // MARK: - Session stop and pause
    /// Stops the current session with the text message. If nil, the default message will be shown
    /// - Parameter message: The message to show
    public func stop(message: String? = nil, completion: (() -> Void)? = nil) {
        Log.session("Stop session")
        if let message = message {
            viewDelegate.showAlertMessage(message)
        }
        reader.stopSession()
        sessionDidStop(completion: completion)
    }
    
    /// Stops the current session with the error message.  Error's `localizedDescription` will be used
    /// - Parameter error: The error to show
    public func stop(error: Error, completion: (() -> Void)?) {
        Log.session("Stop session")
        reader.stopSession(with: error)
        sessionDidStop(completion: completion)
    }
    
    public func pause(message: String) {
        viewDelegate.showAlertMessage(message)
        reader.pauseSession()
    }
    
    public func pause(error: TangemSdkError? = nil) {
        reader.pauseSession(with: error?.localizedDescription)
    }
    
    public func resume() {
        reader.resumeSession()
    }
    
    // MARK: - Restart polling
    /// Restarts the polling sequence so the reader session can discover new tags.
    /// - Parameter silent: If true, view delegate's tag lost/connected events will not be called
    public func restartPolling(silent: Bool = false) {
        Log.session("Restart polling")
        reader.restartPolling(silent: silent)
    }
    
    // MARK: - APDU sending
    /// Sends `CommandApdu` to the current card
    /// - Parameters:
    ///   - apdu: The apdu to send
    ///   - completion: Completion handler. Invoked by nfc-reader
    public final func send(apdu: CommandApdu, completion: @escaping CompletionResult<ResponseApdu>) {
        Log.session("Send")

        guard sendSubscription.isEmpty else {
            Log.error(TangemSdkError.busy)
            completion(.failure(.busy))
            return
        }
        
        guard state == .active else {
            Log.error(TangemSdkError.sessionInactive)
            completion(.failure(.sessionInactive))
            return
        }

        reader.tag
            .filter { $0 != .none }
            .filter {[weak self] tag in
                guard let self else { return false }

                guard self.currentTag != .none else { return true } //Skip filtration because we have nothing to compare with
                
                if tag != self.currentTag { //handle wrong tag connection during any operation
                    let formatter = CardIdFormatter(style: self.environment.config.cardIdDisplayFormat)
                    let cardId = self.environment.card?.cardId
                    let cardIdFormatted = cardId.flatMap {
                        formatter.string(from: $0)
                    }
                    self.viewDelegate.wrongCard(message: TangemSdkError.wrongCardNumber(expectedCardId: cardIdFormatted).localizedDescription)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.restartPolling()
                    }
                    return false
                } else {
                    return true
                }
            }
            .flatMap { _ in self.establishEncryptionIfNeeded() }
            .flatMap { apdu.encryptPublisher(encryptionMode: self.environment.encryptionMode, encryptionKey: self.environment.encryptionKey) }
            .flatMap { self.reader.sendPublisher(apdu: $0) }
            .flatMap { $0.decryptPublisher(encryptionKey: self.environment.encryptionKey) }
            .sink(receiveCompletion: {[weak self] readerCompletion in
                self?.sendSubscription = []
                if case let .failure(error) = readerCompletion {
                    completion(.failure(error))
                }
            }, receiveValue: {[weak self] responseApdu in
                self?.sendSubscription = []
                completion(.success(responseApdu))
            })
            .store(in: &sendSubscription)
    }
    
    /// Update session environment config with the new one
    public func updateConfig(with newConfig: Config) {
        environment.config = newConfig
    }
    
    /// We need to remember the tag for the duration of the command to be able to compare this tag with new one on tag from connected/lost events
    func rememberTag() {
        guard case .tag = reader.tag.value else { return }
        
        currentTag = reader.tag.value
    }
    
    /// The command has been completed. We don't need this tag anymore
    func releaseTag() {
        currentTag = .none
    }
    
    private func sessionDidStop(completion: (() -> Void)?) {
        nfcReaderSubscriptions = []
        resetEnvironment()
        preflightReadMode = .fullCardRead
        sendSubscription = []
        viewDelegate.sessionStopped(completion: completion)
        state = .inactive
    }
    
    // MARK: - Prepearing session
    private func prepareSession<T: CardSessionRunnable>(for runnable: T, completion: @escaping CompletionResult<Void>) {
        Log.session("Prepare card session")
        preflightReadMode = runnable.preflightReadMode
        environment.encryptionMode = runnable.encryptionMode

        Log.session("Access code policy is \(environment.config.accessCodeRequestPolicy)")
        Log.session("Encryption mode is \(environment.encryptionMode)")

        guard runnable.shouldAskForAccessCode else {
            Log.session("Skip an access codes request")
            runnable.prepare(self, completion: completion)
            return
        }
        
        let requestAccessCodeAction = {
            Log.session("Request for an access code")
            self.environment.accessCode = UserCode(.accessCode, value: nil)
            self.requestUserCodeIfNeeded(.accessCode) { result in
                switch result {
                case .success:
                    Log.session("Continue the runnable")
                    runnable.prepare(self, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        switch environment.config.accessCodeRequestPolicy {
        case .alwaysWithBiometrics:
            if shouldRequestBiometrics {
                Log.session("Request the biometric auth")
                let reason = environment.config.biometricsLocalizedReason
                accessCodeRepository?.unlock(localizedReason: reason) { result in
                     switch result {
                     case .success:
                         Log.session("Biometric auth completed successfully")
                         runnable.prepare(self, completion: completion)
                     case .failure:
                         requestAccessCodeAction()
                     }
                 }
            } else {
                requestAccessCodeAction()
            }
        case .always:
            requestAccessCodeAction()
        case .default:
            runnable.prepare(self, completion: completion)
        }
    }
    
    // MARK: - Preflight check
    private func preflightCheck(_ onSessionStarted: @escaping (CardSession, TangemSdkError?) -> Void) {
        Log.session("Start preflight check")
        let preflightTask = PreflightReadTask(readMode: preflightReadMode, filter: filter?.preflightReadFilter)
        preflightTask.run(in: self) { [weak self] readResult in
            guard let self = self else { return }
            
            switch readResult {
            case .success:
                onSessionStarted(self, nil)
            case .failure(let error):
                switch error {
                case .preflightFiltered:
                    self.viewDelegate.wrongCard(message: error.localizedDescription)
                    // We have to return environment to initial state to reset all the changes
                    self.resetEnvironment()
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        guard self.reader.isReady else {
                            onSessionStarted(self, .userCancelled)
                            self.stop(completion: nil)
                            return
                        }
                        
                        self.restartPolling()
                        self.preflightCheck(onSessionStarted)
                    }
                default:
                    onSessionStarted(self, error)
                    self.stop(error: error, completion: nil)
                }
            }
        }
    }
    
    private func establishEncryptionIfNeeded() -> AnyPublisher<Void, TangemSdkError> {
        if self.environment.encryptionMode == .none || self.environment.encryptionKey != nil {
            return Just(()).setFailureType(to: TangemSdkError.self).eraseToAnyPublisher()
        }
        
        Log.session("Try establish encryption")
        
        do {
            let encryptionHelper = try EncryptionHelperFactory.make(for: self.environment.encryptionMode)
            let openSessionCommand = OpenSessionCommand(sessionKeyA: encryptionHelper.keyA)
            let openSesssionApdu = try openSessionCommand.serialize(with: self.environment)
            return reader
                .sendPublisher(apdu: openSesssionApdu)
                .tryMap { responseApdu -> Void in
                    let response = try openSessionCommand.deserialize(with: self.environment, from: responseApdu)
                    
                    var uid: Data
                    if let uidFromResponse = response.uid {
                        uid = uidFromResponse
                    } else {
                        if case let .tag(tagUid) = self.reader.tag.value {
                            uid = tagUid
                        } else {
                            throw TangemSdkError.failedToEstablishEncryption
                        }
                    }
                    
                    guard let accessCode = self.environment.accessCode.value else {
                        throw TangemSdkError.accessCodeRequired
                    }
                    
                    let protocolKey = try accessCode.pbkdf2sha256(salt: uid, rounds: 50)
                    let secret = try encryptionHelper.generateSecret(keyB: response.sessionKeyB)
                    let sessionKey = (secret + protocolKey).getSha256()
                    self.environment.encryptionKey = sessionKey

                    Log.session("The encryption established")
                    return ()
                }
                .mapError{$0.toTangemSdkError()}
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error.toTangemSdkError()).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Request User code
    func requestUserCodeIfNeeded(_ type: UserCodeType, _ completion: @escaping CompletionResult<Void>) {
        switch type {
        case .accessCode:
            guard environment.accessCode.value == nil else {
                completion(.success(()))
                return
            }
        case .passcode:
            guard environment.passcode.value == nil else {
                completion(.success(()))
                return
            }
        }
        Log.session("Request user code of type: \(type)")
        
        
        let cardId = environment.card?.cardId ?? self.cardId
        let showForgotButton = environment.card?.backupStatus?.isActive ?? false
        let formattedCardId = cardId.flatMap { CardIdFormatter(style: environment.config.cardIdDisplayFormat).string(from: $0) }
        
        viewDelegate.setState(.requestCode(type, cardId: formattedCardId, showForgotButton: showForgotButton, completion: { [weak self] result in
            guard let self = self else { return }
            
            func continueRunnable(code: String) {
                self.updateEnvironment(with: type, code: code)
                self.viewDelegate.setState(.default)
                self.viewDelegate.showAlertMessage(defaultScanMessage)
                completion(.success(()))
            }
            
            switch result {
            case .success(let code):
                continueRunnable(code: code)
            case .failure(let error):
                if case .userForgotTheCode = error {
                    self.viewDelegate.sessionStopped {
                        self.restoreUserCode(type, cardId: cardId) { result in
                            switch result {
                            case .success(let newCode):
                                continueRunnable(code: newCode)
                                self.resetCodesController = nil
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }))
    }
    
    func fetchAccessCodeIfNeeded() {
        Log.session("Try fetch an access code")
        guard let card = environment.card, card.isAccessCodeSet,
              let accessCodeValue = accessCodeRepository?.fetch(for: card.cardId) else {
            return
        }

        Log.session("The access code fetched successfully")
        environment.accessCode = UserCode(.accessCode, value: accessCodeValue)
    }
    
    func saveAccessCodeIfNeeded() {
        Log.session("Try save an access code")
        guard let card = environment.card,
              let code = environment.accessCode.value else {
            return
        }
        
        do {
            try accessCodeRepository?.save(code, for: card.cardId)
            accessCodeRepository?.lock()
            Log.session("The access code saved successfully")
        } catch {
            Log.error(error)
        }
    }
    
    private func updateEnvironment(with type: UserCodeType, code: String) {
        switch type {
        case .accessCode:
            self.environment.accessCode = UserCode(.accessCode, stringValue: code)
        case .passcode:
            self.environment.passcode = UserCode(.passcode, stringValue: code)
        }
    }
    
    private func restoreUserCode(_ type: UserCodeType, cardId: String?, _ completion: @escaping CompletionResult<String>) {
        var config = environment.config
        config.accessCodeRequestPolicy = .default
        let resetService = ResetPinService(config: config)
        let viewDelegate = ResetCodesViewDelegate(style: config.style)
        resetCodesController = ResetCodesController(resetService: resetService, viewDelegate: viewDelegate)
        resetCodesController!.cardIdDisplayFormat = config.cardIdDisplayFormat
        resetCodesController!.start(codeType: type, cardId: cardId, completion: completion)
    }

    private func resetEnvironment() {
        _environment.resetCodes()
        environment = _environment
    }
}
//MARK: - JSON RPC
extension CardSession {
    /// Convinience method for jsonrpc requests running
    /// - Parameters:
    ///   - jsonRequest: request to run
    ///   - completion: CardSessionRunnable response converted to json string
    func run(jsonRequest: String, completion: @escaping (String) -> Void) {
        var request: JSONRPCRequest!
        do {
            request = try JSONRPCRequest(jsonString: jsonRequest)
            let runnable = try jsonConverter.convert(request: request)
            runnable.run(in: self) {
                completion($0.toJsonResponse(id: request.id).json)
                self.resetEnvironment()
            }
        } catch {
            completion(error.toJsonResponse(id: request?.id).json)
        }
    }
}
