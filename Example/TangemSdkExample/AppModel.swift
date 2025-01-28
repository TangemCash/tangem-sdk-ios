//
//  Model.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 04.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import Combine

class AppModel: ObservableObject {
    //MARK:- Inputs
    @Published var method: Method = .scan
    
    //Wallet creation
    @Published var curve: EllipticCurve = .secp256k1
    @Published var mnemonicString: String = ""
    @Published var passphrase: String = ""
    //Sign
    @Published var derivationPath: String = ""
    @Published var signHashesCount: String = "15"
    //Attestation
    @Published var attestationMode: AttestationTask.Mode = .normal
    //JSON-RPC
    @Published var json: String =  ""
    //Personalization
    @Published var personalizationConfig: String =  ""
    //Set user code recovery allowed
    @Published var isUserCodeRecoveryAllowed: Bool = false
    
    //MARK:-  Outputs
    @Published var logText: String = DebugLogger.logPlaceholder
    @Published var isScanning: Bool = false
    @Published var card: Card?
    @Published var showWalletSelection: Bool = false
    //MARK:-  Navigation
    @Published var showBackupView: Bool = false
    @Published var showResetPin: Bool = false
    @Published var showSettings: Bool = false
    //MARK:-  Config
    @Published var handleErrors: Bool = true
    @Published var displayLogs: Bool = false
    @Published var accessCodeRequestPolicy: AccessCodeRequestPolicy = .default
    
    var backupService: BackupService? = nil
    var resetPinService: ResetPinService? = nil
    
    private lazy var _tangemSdk: TangemSdk = { .init() }()
    private lazy var logger: DebugLogger = .init()
    
    private var tangemSdk: TangemSdk {
        var config = Config()
        config.linkedTerminal = false
        config.allowUntrustedCards = true
        config.handleErrors = self.handleErrors
        config.filter.allowedCardTypes = FirmwareVersion.FirmwareType.allCases
        config.accessCodeRequestPolicy = accessCodeRequestPolicy

        var loggers: [TangemSdkLogger] = [ConsoleLogger()]

        if displayLogs {
            loggers.append(logger)
        }

        config.logConfig = .custom(
            logLevel: Log.Level.allCases,
            loggers: [ConsoleLogger(), logger]
        )

        config.defaultDerivationPaths = [
            .secp256k1: [try! DerivationPath(rawPath: "m/0'/1")],
            .secp256r1: [try! DerivationPath(rawPath: "m/0'/1")],
            .ed25519: [try! DerivationPath(rawPath: "m/0'/1")],
            .ed25519_slip0010: [try! DerivationPath(rawPath: "m/0'/1'")],
            .bip0340: [try! DerivationPath(rawPath: "m/0'/1")]
        ]

        _tangemSdk.config = config
        return _tangemSdk
    }
    
    private var issuerDataResponse: ReadIssuerDataResponse?
    private var issuerExtraDataResponse: ReadIssuerExtraDataResponse?
    private var savedFiles: [File]?
    private var bag: Set<AnyCancellable> = []
    
    init() {
        logger
            .logsPublisher
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink {[weak self] logs in
                self?.logText = logs
            }
            .store(in: &bag)
    }
    
    func clear() {
        logText = ""
        logger.clear()
    }
    
    func copy() {
        UIPasteboard.general.string = logText
    }

    func hideKeyboard() {
        UIApplication.shared.endEditing()
    }
    
    func start(walletPublicKey: Data? = nil) {
        isScanning = true
        chooseMethod(walletPublicKey: walletPublicKey)
    }
    
    func onAppear() {
        if json.isEmpty {
            json = AppModel.jsonRpcTemplate
        }
        
        if personalizationConfig.isEmpty {
            personalizationConfig = AppModel.personalizeConfigTemplate
        }
    }
    
    private func handleCompletion<T>(_ completionResult: Result<T, TangemSdkError>) -> Void {
        switch completionResult {
        case .success(let response):
            self.complete(with: response)
        case .failure(let error):
            self.complete(with: error)
        }
    }
    
    private func complete(with object: Any) {
        logger.log(object)
        isScanning = false
    }
    
    private func complete(with error: TangemSdkError) {
        if !error.isUserCancelled {
            logger.log("\(error.localizedDescription)")
        }
        
        isScanning = false
    }
    
    private func getRandomHash(size: Int = 32) -> Data {
        let array = (0..<size).map{ _ -> UInt8 in
            UInt8(arc4random_uniform(255))
        }
        return Data(array)
    }
    
    private func runWithPublicKey(_ method: (_ walletPublicKey: Data) -> Void, _ walletPublicKey: Data?) {
        if let publicKey = walletPublicKey {
            method(publicKey)
            return
        }
        
        guard let card = card, !card.wallets.isEmpty else {
            self.complete(with: "Scan card to retrieve wallet")
            return
        }
        
        if card.wallets.count == 1 {
            method(card.wallets.first!.publicKey)
        } else {
            showWalletSelection.toggle()
        }
    }
}

// MARK:- Editor
extension AppModel {
    var editorData: String {
        get {
            switch method {
            case .jsonrpc:
                return json
            case .personalize:
                return personalizationConfig
            default: return ""
            }
        }
        
        set {
            switch method {
            case .jsonrpc:
                json = newValue
            case .personalize:
                personalizationConfig = newValue
            default: break
            }
        }
    }
    
    func pasteEditor() {
        switch method {
        case .jsonrpc:
            pasteJson()
        case .personalize:
            pastePersonalizationConfig()
        default: break
        }
    }
    
    func endEditing() {
        UIApplication.shared.endEditing()
    }
}

// MARK:- Commands
extension AppModel {
    func scan() {
        tangemSdk.scanCard(initialMessage: Message(header: "Scan Card", body: "Tap Tangem Card to learn more")) { result in
            if case let .success(card) = result {
                self.card = card
                self.curve = card.supportedCurves[0]
            }
            
            self.handleCompletion(result)
        }
    }
    
    func attest() {
        tangemSdk.startSession(with: AttestationTask(mode: attestationMode), completion: handleCompletion)
    }

    func attestCard() {
        tangemSdk.attestCardKey(attestationMode: .full, completion: handleCompletion)
    }
    
    func signHash(walletPublicKey: Data) {
        let path = try? DerivationPath(rawPath: derivationPath)
        if !derivationPath.isEmpty && path == nil {
            self.complete(with: "Failed to parse hd path")
            return
        }
        
        UIApplication.shared.endEditing()
        
        guard let wallet = self.card?.wallets[walletPublicKey] else {
            self.complete(with: "Scan card before")
            return
        }

        let verifyKey = (path.flatMap { wallet.derivedKeys[$0] })?.publicKey ?? walletPublicKey
        
        let hashSize = wallet.curve == .ed25519 ? 64 : 32
        let hash = getRandomHash(size: hashSize)
        
        tangemSdk.sign(hash: hash,
                       walletPublicKey: walletPublicKey,
                       cardId: nil,
                       derivationPath: path,
                       initialMessage: Message(header: "Signing hash")) { result in

            if case .success(let response) = result {
                if #available(iOS 16.0, *), wallet.curve == .secp256r1 {
                    let isValid = try? CryptoUtils.verifySecp256r1Signature(publicKey: verifyKey, hash: hash, signature: response.signature)
                    self.logger.log("signature status: \(String(describing: isValid))")
                } else  {
                    let isValid = try? CryptoUtils.verify(curve: wallet.curve, publicKey: verifyKey, hash: hash, signature: response.signature)
                    self.logger.log("signature status: \(String(describing: isValid))")
                }
            }

            self.handleCompletion(result)
        }
    }
    
    func signHashes(walletPublicKey: Data) {
        let path = try? DerivationPath(rawPath: derivationPath)
        if !derivationPath.isEmpty && path == nil {
            self.complete(with: "Failed to parse hd path")
            return
        }

        guard let hashesCount = Int(signHashesCount, radix: 10) else {
            self.complete(with: "Failed to signed hashes count")
            return
        }
        
        UIApplication.shared.endEditing()
        
        let hashes = (0..<hashesCount).map {_ -> Data in getRandomHash()}
        
        tangemSdk.sign(hashes: hashes,
                       walletPublicKey: walletPublicKey,
                       cardId: nil,
                       derivationPath: path,
                       initialMessage: Message(header: "Signing hashes"),
                       completion: handleCompletion)
    }
    
    func derivePublicKey(walletPublicKey: Data) {
        guard let card = card else {
            self.complete(with: "Scan card before")
            return
        }
        
        guard let path = try? DerivationPath(rawPath: derivationPath) else {
            self.complete(with: "Failed to parse hd path")
            return
        }
        
        UIApplication.shared.endEditing()
        
        tangemSdk.deriveWalletPublicKey(cardId: card.cardId,
                                        walletPublicKey: walletPublicKey,
                                        derivationPath: path,
                                        completion: handleCompletion)
    }
    
    func createWallet() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }

        tangemSdk.createWallet(curve: curve,
                               cardId: cardId,
                               completion: handleCompletion)
    }

    func importWallet() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }

        tangemSdk.importWallet(curve: curve,
                               cardId: cardId,
                               mnemonic: mnemonicString,
                               passphrase: passphrase,
                               completion: handleCompletion)
    }
    
    func purgeWallet(walletPublicKey: Data) {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.purgeWallet(walletPublicKey: walletPublicKey,
                              cardId: cardId,
                              completion: handleCompletion)
    }
    
    func chainingExample() {
        tangemSdk.startSession(cardId: nil) { session, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.complete(with: error)
                }
                return
            }
            
            let scan = ScanTask()
            scan.run(in: session) { result in
                switch result {
                case .success:
                    session.resume()
                    let secondTaskDelay: TimeInterval = 3
                    DispatchQueue.main.asyncAfter(deadline: .now() + secondTaskDelay) {
                        let createWallet = CreateWalletTask(curve: .secp256k1)
                        createWallet.run(in: session) { result2 in
                            switch result2 {
                            case .success(let response):
                                self.logger.log(response)
                            case .failure:
                                break
                            }
                            
                            DispatchQueue.main.async {
                                self.handleCompletion(result)
                            }
                            
                            session.stop()
                        }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.complete(with: error)
                    }
                    session.stop()
                }
            }
        }
    }
    
    func depersonalize() {
        tangemSdk.startSession(with: DepersonalizeCommand(), completion: handleCompletion)
    }
    
    func setAccessCode() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.setAccessCode(nil,
                                cardId: cardId,
                                completion: handleCompletion)
    }
    
    func setPasscode() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.setPasscode(nil,
                              cardId: cardId,
                              completion: handleCompletion)
    }
    
    func resetUserCodes() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        tangemSdk.resetUserCodes(cardId: cardId,
                                 completion: handleCompletion)
    }
}

//MARK:- Files
extension AppModel {
    func readFiles() {
        //let wallet = Data(hexString: "40D2D7CFEF2436C159CCC918B7833FCAC5CB6037A7C60C481E8CA50AF9EDC70B")
        tangemSdk.readFiles(readPrivateFiles: true,
                            fileName: nil,
                            walletPublicKey: nil) { result in
            switch result {
            case .success(let files):
                var text = ""
                for file in files {
                    text += file.json + "\n\n"
                    text += "Name: \(String(describing: file.name))" + "\n"
                    text += "File data: \(file.data.hexString)" + "\n\n"
                    
                    if let tlv = Tlv.deserialize(file.data) {
                        let decoder = TlvDecoder(tlv: tlv)
                        let deserializer = WalletDataDeserializer()
                        if let walletData = try? deserializer.deserialize(decoder: decoder) {
                            text += "WalletData: \(walletData.json)" + "\n\n"
                        }
                    }
                }
                
                if files.isEmpty {
                    text = "No files on the card"
                }
                self.complete(with: text)
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }
    
    
    func writeUserFile() {
        let demoPayload = Data(repeating: UInt8(1), count: 10)
        //let walletPublicKey = Data(hexString: "40D2D7CFEF2436C159CCC918B7833FCAC5CB6037A7C60C481E8CA50AF9EDC70B")
        let file: FileToWrite = .byUser(data: demoPayload,
                                        fileName: "User file",
                                        fileVisibility: .public,
                                        walletPublicKey: nil)
        
        tangemSdk.writeFiles(files: [file], completion: handleCompletion)
    }
    
    func writeOwnerFile() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        let filename = "Issuer file"
        let demoPayload = Data(repeating: UInt8(2), count: 10)
        let counter = 1
        //let walletPublicKey = Data(hexString: "40D2D7CFEF2436C159CCC918B7833FCAC5CB6037A7C60C481E8CA50AF9EDC70B")
        
        let fileHash = try! FileHashHelper.prepareHash(for: cardId,
                                                       fileData: demoPayload,
                                                       fileCounter: counter,
                                                       fileName: filename,
                                                       privateKey: Utils.issuer.privateKey)
        guard
            let startSignature = fileHash.startingSignature,
            let finalSignature = fileHash.finalizingSignature else {
            self.complete(with: "Failed to sign data with issuer signature")
            return
        }
        
        let file: FileToWrite = .byFileOwner(data: demoPayload,
                                             startingSignature: startSignature,
                                             finalizingSignature: finalSignature,
                                             counter: counter,
                                             fileName: filename,
                                             fileVisibility: .public,
                                             walletPublicKey: nil)
        
        tangemSdk.writeFiles(files: [file], completion: handleCompletion)
    }
    
    func deleteFile() {
        tangemSdk.deleteFiles(indices: [0], completion: handleCompletion)
    }
    
    func updateFilePermissions() {
        var changes: [Int:FileVisibility] = .init()
        changes[0] = .public
        
        let changeTask = ChangeFileSettingsTask(changes: changes)
        tangemSdk.startSession(with: changeTask, completion: handleCompletion)
    }
}

//MARK:- Deprecated commands
extension AppModel {
    func readUserData() {
        tangemSdk.readUserData(cardId: card?.cardId,
                               completion: handleCompletion)
    }
    
    func writeUserData() {
        let userData = Data(hexString: "0102030405060708")
        
        tangemSdk.writeUserData(userData: userData,
                                userCounter: 2,
                                cardId: card?.cardId,
                                completion: handleCompletion)
    }
    
    func writeUserProtectedData() {
        let userData = Data(hexString: "01010101010101")
        
        tangemSdk.writeUserProtectedData(userProtectedData: userData,
                                         userProtectedCounter: 1,
                                         cardId: card?.cardId,
                                         completion: handleCompletion)
    }
    
    func readIssuerData() {
        tangemSdk.readIssuerData(cardId: card?.cardId,
                                 initialMessage: Message(header: "Read issuer data", body: "This is read issuer data request")){ result in
            switch result {
            case .success(let issuerDataResponse):
                self.issuerDataResponse = issuerDataResponse
                self.complete(with: issuerDataResponse)
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }
    
    func writeIssuerData() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Scan card to retrieve cardId")
            return
        }
        
        
        guard let issuerDataResponse = issuerDataResponse else {
            self.complete(with: "Please, run ReadIssuerData before")
            return
        }
        
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 100)
        let sig = try! Secp256k1Utils().sign(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: Utils.issuer.privateKey)
        
        tangemSdk.writeIssuerData(issuerData: sampleData,
                                  issuerDataSignature: sig,
                                  issuerDataCounter: newCounter,
                                  cardId: cardId,
                                  completion: handleCompletion)
    }
    
    func readIssuerExtraData() {
        tangemSdk.readIssuerExtraData(cardId: card?.cardId){ result in
            switch result {
            case .success(let issuerDataResponse):
                self.issuerExtraDataResponse = issuerDataResponse
                self.complete(with: issuerDataResponse)
                print(issuerDataResponse.issuerData)
            case .failure(let error):
                self.complete(with: error)
            }
        }
    }
    
    func writeIssuerExtraData() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Please, scan card before")
            return
        }
        
        
        guard let issuerDataResponse = issuerExtraDataResponse else {
            self.complete(with: "Please, run ReadIssuerExtraData before")
            return
        }
        let newCounter = (issuerDataResponse.issuerDataCounter ?? 0) + 1
        let sampleData = Data(repeating: UInt8(1), count: 2000)
        let issuerKey = Utils.issuer.privateKey
        let secp256k1 = Secp256k1Utils()
        let startSig = try! secp256k1.sign(Data(hexString: cardId) + newCounter.bytes4 + sampleData.count.bytes2, with: issuerKey)
        let finalSig = try! secp256k1.sign(Data(hexString: cardId) + sampleData + newCounter.bytes4, with: issuerKey)
        
        tangemSdk.writeIssuerExtraData(issuerData: sampleData,
                                       startingSignature: startSig,
                                       finalizingSignature: finalSig,
                                       issuerDataCounter: newCounter,
                                       cardId: cardId,
                                       completion: handleCompletion)
    }
    
    func resetBackup() {
        tangemSdk.startSession(with: ResetBackupCommand(), completion: handleCompletion)
    }

    func resetToFactory() {
        tangemSdk.startSession(with: ResetToFactorySettingsTask(), completion: handleCompletion)
    }

    func getEntropy() {
        tangemSdk.startSession(with: GetEntropyCommand(), completion: handleCompletion)
    }

    func setUserCodeRecoveryAllowed() {
        guard let cardId = card?.cardId else {
            self.complete(with: "Please, scan card before")
            return
        }

        tangemSdk.setUserCodeRecoveryAllowed(isUserCodeRecoveryAllowed, cardId: cardId, completion: handleCompletion)
    }
}

//MARK:- Json RPC
extension AppModel {    
    func runJsonRpc() {
        UIApplication.shared.endEditing()
        tangemSdk.startSession(with: json) { self.complete(with: $0) }
    }
    
    private func pasteJson() {
        if let string = UIPasteboard.general.string {
            json = string
        }
    }
}

//personalization
extension AppModel {
    private func pastePersonalizationConfig() {
        if let string = UIPasteboard.general.string {
            personalizationConfig = string
        }
    }
    
    func personalize() {
        do {
            guard let configData = personalizationConfig.data(using: .utf8) else {
                throw TangemSdkError.decodingFailed("Failed to convert congif to data")
            }
            
            let config = try JSONDecoder.tangemSdkDecoder.decode(CardConfig.self, from: configData)
            let issuer = try JSONDecoder.tangemSdkDecoder.decode(Issuer.self, from: AppModel.issuerJson.data(using: .utf8)!)
            let manufacturer = try JSONDecoder.tangemSdkDecoder.decode(Manufacturer.self, from: AppModel.manufacturerJson.data(using: .utf8)!)
            let personalizeCommand = PersonalizeCommand(config: config,
                                                        issuer: issuer,
                                                        manufacturer: manufacturer)
            
            tangemSdk.startSession(with: personalizeCommand, completion: handleCompletion)
        } catch {
            logger.log(error)
        }
    }
}


extension AppModel {
    enum Method: String, CaseIterable {
        case scan
        case signHash
        case signHashes
        case derivePublicKey
        case attest
        case attestCard
        case chainingExample
        case setAccessCode
        case setPasscode
        case resetUserCodes
        case createWallet
        case importWallet
        case purgeWallet
        //files
        case readFiles
        case writeUserFile
        case writeOwnerFile
        case deleteFile
        case updateFilePermissions
        //case json-rpc
        case jsonrpc
        //deprecated
        case readIssuerData
        case writeIssuerData
        case readIssuerExtraData
        case writeIssuerExtraData
        case readUserData
        case writeUserData
        case writeUserProtectedData
        //developer
        case depersonalize
        case personalize
        case resetBackup
        case resetToFactory
        case getEntropy
        case setUserCodeRecoveryAllowed
    }
    
    private func chooseMethod(walletPublicKey: Data? = nil) {
        switch method {
        case .attest: attest()
        case .attestCard: attestCard()
        case .chainingExample: chainingExample()
        case .setAccessCode: setAccessCode()
        case .setPasscode: setPasscode()
        case .resetUserCodes: resetUserCodes()
        case .depersonalize: depersonalize()
        case .scan: scan()
        case .signHash: runWithPublicKey(signHash, walletPublicKey)
        case .signHashes: runWithPublicKey(signHashes, walletPublicKey)
        case .createWallet: createWallet()
        case .importWallet: importWallet()
        case .purgeWallet: runWithPublicKey(purgeWallet, walletPublicKey)
        case .readFiles: readFiles()
        case .writeUserFile: writeUserFile()
        case .writeOwnerFile: writeOwnerFile()
        case .deleteFile: deleteFile()
        case .updateFilePermissions: updateFilePermissions()
        case .readIssuerData: readIssuerData()
        case .writeIssuerData: writeIssuerData()
        case .readIssuerExtraData: readIssuerExtraData()
        case .writeIssuerExtraData: writeIssuerExtraData()
        case .readUserData: readUserData()
        case .writeUserData: writeUserData()
        case .writeUserProtectedData: writeUserProtectedData()
        case .derivePublicKey: runWithPublicKey(derivePublicKey, walletPublicKey)
        case .jsonrpc: runJsonRpc()
        case .personalize: personalize()
        case .resetBackup: resetBackup()
        case .resetToFactory: resetToFactory()
        case .getEntropy: getEntropy()
        case .setUserCodeRecoveryAllowed: setUserCodeRecoveryAllowed()
        }
    }
}

//MARK: - Routing
extension AppModel {
    func onBackup() {
        backupService = BackupService(sdk: tangemSdk)
        showBackupView = true
    }
    
    func onSettings() {
        showSettings = true
    }
    
    func onRemoveAccessCodes() {
        let repo = AccessCodeRepository()
        repo.clear()
    }
    
    func onResetService() {
        resetPinService = ResetPinService(config: tangemSdk.config)
        showResetPin = true
    }
    
    @ViewBuilder
    func makeSettingsDestination() -> some View {
        SettingsView().environmentObject(self)
    }
    
    @ViewBuilder
    func makeBackupDestination() -> some View {
        if let service = self.backupService {
            BackupView(backupService: service)
        } else {
           EmptyView()
        }
    }
    
    @ViewBuilder
    func makePinResetDestination() -> some View {
        if let service = self.resetPinService {
            ResetPinView(resetPinService: service)
        } else {
            EmptyView()
        }
    }
}
