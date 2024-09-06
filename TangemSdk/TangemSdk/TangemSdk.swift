//
//  CardManager.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC
import Combine

/// The main interface of Tangem SDK that allows your app to communicate with Tangem cards.
public final class TangemSdk {
    /// Configuration of the SDK. Do not change the default values unless you know what you are doing
    public var config = Config()
    
    private let reader: CardReader
    private let viewDelegate: SessionViewDelegate
    private let onlineCardVerifier = OnlineCardVerifier()
    private let terminalKeysService = TerminalKeysService()
    private var cardSession: CardSession? = nil
    private var onlineVerificationCancellable: AnyCancellable? = nil
    
    private lazy var jsonConverter: JSONRPCConverter = {
        return .shared
    }()
    
    /// Default initializer
    /// - Parameters:
    ///   - cardReader: An interface that is responsible for NFC connection and transfer of data to and from the Tangem Card.
    ///   If nil, its default implementation will be used
    ///   - viewDelegate:  An interface that allows interaction with users and shows relevant UI.
    ///   If nil, its default implementation will be used
    ///   - config: Allows to change a number of parameters for communication with Tangem cards.
    ///   Do not change the default values unless you know what you are doing.
    public init(cardReader: CardReader? = nil, viewDelegate: SessionViewDelegate? = nil, config: Config = Config()) {
        let reader = cardReader ?? NFCReader()
        self.reader = reader
        self.viewDelegate = viewDelegate ?? DefaultSessionViewDelegate(reader: reader, style: config.style)
        self.config = config
    }
    
    deinit {
        Log.debug("TangemSdk deinit")
    }
    
    /// Register custom task, that supported JSONRPC
    /// - Parameter object: object, that conforms `JSONRPCHandler`
    public func registerJSONRPCTask(_ object: JSONRPCHandler) {
        jsonConverter.register(object)
    }
}

//MARK: - Card operations
public extension TangemSdk {
    //MARK: - Common
    
    /// To start using any card, you first need to read it using the `scanCard()` method.
    /// This method launches an NFC session, and once it’s connected with the card,
    /// it obtains the card data. Optionally, if the card contains a wallet (private and public key pair),
    /// it proves that the wallet owns a private key that corresponds to a public one.
    /// After successfull card scan, SDK will attempt to verify release cards online with Tangem backend.
    ///
    /// - Parameters:
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<Card,TangemSdkError>`
    func scanCard(initialMessage: Message? = nil,
                  completion: @escaping CompletionResult<Card>) {
        startSession(with: ScanTask(), cardId: nil, initialMessage: initialMessage, completion: completion)
    }

    /// Perform a card's key attestation
    /// - Parameters:
    ///   - attestationMode: Attestation mode to use. Full attestation available only for COS v6+. Usefull to getting all public keys of linked cards.
    ///   - challenge: Optional challenge. If nil, it will be created automatically and returned in command response
    ///   - cardId: CID, Unique Tangem card ID number
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns  `Swift.Result<AttestCardKeyResponse,TangemSdkError>`
    func attestCardKey(attestationMode: AttestCardKeyCommand.Mode = .default,
                       challenge: Data? = nil,
                       cardId: String? = nil,
                       initialMessage: Message? = nil,
                       completion: @escaping CompletionResult<AttestCardKeyResponse>) {
        let command = AttestCardKeyCommand(mode: attestationMode, challenge: challenge)
        startSession(with: command,
                     cardId: cardId,
                     initialMessage: initialMessage,
                     completion: completion)
    }
    
    /// This method allows you to sign one hash and will return a corresponding signature.
    /// Please note that Tangem cards usually protect the signing with a security delay
    /// that may last up to 45 seconds, depending on a card.
    /// It is for `SessionViewDelegate` to notify users of security delay.
    ///
    /// - Note: `WalletIndex` available for cards with COS v.4.0 and higher
    /// - Parameters:
    ///   - hash: Transaction hash for sign by card.
    ///   - walletPublicKey: Public key of wallet that should sign hash.
    ///   - cardId: CID, Unique Tangem card ID number
    ///   - derivationPath: Derivation path of the wallet. Optional
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns  `Swift.Result<SignHashResponse,TangemSdkError>`
    func sign(hash: Data,
              walletPublicKey: Data,
              cardId: String? = nil,
              derivationPath: DerivationPath? = nil,
              initialMessage: Message? = nil,
              completion: @escaping CompletionResult<SignHashResponse>) {
        let command = SignHashCommand(hash: hash, walletPublicKey: walletPublicKey, derivationPath: derivationPath)
        startSession(with: command,
                     cardId: cardId,
                     initialMessage: initialMessage,
                     completion: completion)
    }
    
    /// This method allows you to sign multiple hashes.
    /// Simultaneous signing of array of hashes in a single `SignCommand` is required to support
    /// Bitcoin-type multi-input blockchains (UTXO).
    /// The `SignCommand` will return a corresponding array of signatures.
    /// Please note that Tangem cards usually protect the signing with a security delay
    /// that may last up to 45 seconds, depending on a card.
    /// It is for `SessionViewDelegate` to notify users of security delay.
    ///
    /// - Note: `WalletIndex` available for cards with COS v. 4.0 and higher
    /// - Parameters:
    ///   - hashes: Array of transaction hashes. It can be from one or up to ten hashes of the same length.
    ///   - walletPublicKey: Public key of wallet that should sign hashes.
    ///   - cardId: CID, Unique Tangem card ID number
    ///   - derivationPath: Derivation path of the wallet. Optional. COS v. 4.28 and higher,
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns  `Swift.Result<SignHashesResponse,TangemSdkError>`
    func sign(hashes: [Data],
              walletPublicKey: Data,
              cardId: String? = nil,
              derivationPath: DerivationPath? = nil,
              initialMessage: Message? = nil,
              completion: @escaping CompletionResult<SignHashesResponse>) {
        let command = SignCommand(hashes: hashes, walletPublicKey: walletPublicKey, derivationPath: derivationPath)
        startSession(with: command,
                     cardId: cardId,
                     initialMessage: initialMessage,
                     completion: completion)
    }
    
    /// This command will create a new wallet on the card having ‘Empty’ state.
    /// A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
    /// App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand` or `ReadCommand`
    /// and then transform it into an address of corresponding blockchain wallet
    /// according to a specific blockchain algorithm.
    /// WalletPrivateKey is never revealed by the card and will be used by `SignCommand` and `AttestWalletKeyCommand`.
    /// RemainingSignature is set to MaxSignatures.
    ///
    /// - Note: `WalletConfig` available for cards with COS v.4.0 or higher
    /// - Parameters:
    ///   - curve: Elliptic curve of the wallet.  `Card.supportedCurves` contains all curves supported by the card
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - completion: Returns `Swift.Result<CreateWalletResponse,TangemSdkError>`
    func createWallet(curve: EllipticCurve,
                      cardId: String,
                      initialMessage: Message? = nil,
                      completion: @escaping CompletionResult<CreateWalletResponse>) {
        let command = CreateWalletTask(curve: curve)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }

    /// This command will import an esisting wallet
    /// - Parameters:
    ///   - curve: Elliptic curve of the wallet.  `Card.supportedCurves` contains all curves supported by the card
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - mnemonic: BIP39 mnemonic to create wallet from. COS v.6.16+.
    ///   - passphrase: BIP39 passphrase to create wallet from. COS v.6.16+.  Empty passphrase by default.
    ///   - completion: Returns `Swift.Result<CreateWalletResponse,TangemSdkError>`
    func importWallet(curve: EllipticCurve,
                      cardId: String,
                      mnemonic: String,
                      passphrase: String = "",
                      initialMessage: Message? = nil,
                      completion: @escaping CompletionResult<CreateWalletResponse>) {
        do {
            let mnemonic = try Mnemonic(with: mnemonic)
            let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase)
            let privateKey = try factory.makeMasterKey(for: curve)
            let command = CreateWalletTask(curve: curve, privateKey: privateKey)
            startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
        } catch {
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    /// This command deletes all wallet data. If Is_Reusable flag is enabled during personalization,
    /// the card changes state to ‘Empty’ and a new wallet can be created by `CREATE_WALLET` command.
    /// If Is_Reusable flag is disabled, the card switches to ‘Purged’ state.
    /// ‘Purged’ state is final, it makes the card useless.
    ///
    /// - Note: Wallet index available for cards with COS v.4.0 or higher
    /// - Parameters:
    ///   - walletPublicKey: Public key of wallet that should be purged.
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SuccessResponse,TangemSdkError>`
    func purgeWallet(walletPublicKey: Data,
                     cardId: String,
                     initialMessage: Message? = nil,
                     completion: @escaping CompletionResult<SuccessResponse>) {
        startSession(with: PurgeWalletCommand(publicKey: walletPublicKey), cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Get the card info and verify with Tangem backend. Do not use for developer cards
    /// - Parameters:
    ///   - cardPublicKey: CardPublicKey returned by [ReadCommand]
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - completion: `CardVerifyAndGetInfoResponse.Item`
    func loadCardInfo(cardPublicKey: Data,
                      cardId: String,
                      completion: @escaping CompletionResult<CardVerifyAndGetInfoResponse.Item>) {
        onlineVerificationCancellable = onlineCardVerifier
            .getCardInfo(cardId: cardId, cardPublicKey: cardPublicKey)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { receivedCompletion in
                if case let .failure(error) = receivedCompletion {
                    completion(.failure(error.toTangemSdkError()))
                }
            }, receiveValue: { response in
                completion(.success(response))
            })
    }
    
    /// Set or change card's access code
    /// - Parameters:
    ///   - accessCode: Access code to set. If nil, the user will be prompted to enter code before operation
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<UserCodeCommandResponse,TangemSdkError>`
    func setAccessCode(_ accessCode: String? = nil,
                       cardId: String,
                       initialMessage: Message? = nil,
                       completion: @escaping CompletionResult<SuccessResponse>) {
        let command = SetUserCodeCommand(accessCode: accessCode)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Set or change card's passcode
    /// - Parameters:
    ///   - passcode: Passcode to set. If nil, the user will be prompted to enter code before operation
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SuccessResponse,TangemSdkError>`
    func setPasscode(_ passcode: String? = nil,
                     cardId: String,
                     initialMessage: Message? = nil,
                     completion: @escaping CompletionResult<SuccessResponse>) {
        let command = SetUserCodeCommand(passcode: passcode)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Reset all user codes
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SuccessResponse,TangemSdkError>`
    func resetUserCodes(cardId: String,
                        initialMessage: Message? = nil,
                        completion: @escaping CompletionResult<SuccessResponse>) {
        startSession(with: SetUserCodeCommand.resetUserCodes, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }

    /// Set if card allowed to reset user code
    /// - Parameters:
    ///   - isAllowed:Is this card can reset user codes on tte other linked card or not
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SuccessResponse,TangemSdkError>`
    func setUserCodeRecoveryAllowed(_ isAllowed: Bool,
                                    cardId: String,
                                    initialMessage: Message? = nil,
                                    completion: @escaping CompletionResult<SuccessResponse>) {
        let task = SetUserCodeRecoveryAllowedTask(isAllowed: isAllowed)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Derive public key according to BIP32 (Private parent key → public child key)
    /// - Warning: Only `secp256k1` and `ed25519` (BIP32-Ed25519 scheme) curves supported
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - walletPublicKey: Seed public key.
    ///   - derivationPath: Derivation path
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<ExtendedPublicKey,TangemSdkError>`
    func deriveWalletPublicKey(cardId: String,
                               walletPublicKey: Data,
                               derivationPath: DerivationPath,
                               initialMessage: Message? = nil,
                               completion: @escaping CompletionResult<ExtendedPublicKey>) {
        let command = DeriveWalletPublicKeyTask(walletPublicKey: walletPublicKey, derivationPath: derivationPath)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Derive multiple wallet public keys according to BIP32 (Private parent key → public child key)
    /// - Warning: Only `secp256k1` and `ed25519` (BIP32-Ed25519 scheme) curves supported
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - walletPublicKey: Seed public key.
    ///   - derivationPaths: Derivation paths. Repeated items will be ignored.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<DerivedKeys,TangemSdkError>`. All derived keys are unique and will be returned in arbitrary order.
    func deriveWalletPublicKeys(cardId: String,
                                walletPublicKey: Data,
                                derivationPaths: [DerivationPath],
                                initialMessage: Message? = nil,
                                completion: @escaping CompletionResult<DerivedKeys>) {
        let command = DeriveWalletPublicKeysTask(walletPublicKey: walletPublicKey, derivationPaths: derivationPaths)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    //MARK: - Files
    
    /// This command reads all files stored on card.
    ///
    /// By default command trying to read all files (including private), to change this behaviour - setup your ` ReadFileDataTaskSetting `
    /// - Note: When performing reading private files command, you must  provide `passcode`
    /// - Warning: Command available only for cards with COS 3.29 and higher
    /// - Parameters:
    ///   - readPrivateFiles: If true - all files saved on card will be read.  User code or security delay will be requested
    ///   - fileName: Read files by the given name.
    ///   - walletPublicKey: Read files by the given wallet.
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<[File],TangemSdkError>`
    func readFiles(readPrivateFiles: Bool = false,
                   fileName: String? = nil,
                   walletPublicKey: Data? = nil,
                   cardId: String? = nil,
                   initialMessage: Message? = nil,
                   completion: @escaping CompletionResult<[File]>) {
        let task = ReadFilesTask(fileName: fileName, walletPublicKey: walletPublicKey)
        task.shouldReadPrivateFiles = readPrivateFiles
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Updates selected file settings provided within `File`.
    ///
    /// To perform file settings update you should initially read all files (`readFiles` command), select files that you want to update, change their settings in `File.fileSettings` and add them to `files` array.
    /// - Note: In COS 3.29 and higher only file visibility option (public or private) available to update
    /// - Warning: This method works with COS 3.29 and higher
    /// - Parameters:
    ///   - changes: Array of file indecies with new settings
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SuccessResponse, TangemSdkError>`
    func changeFileSettings(changes: [Int: FileVisibility],
                            cardId: String? = nil,
                            initialMessage: Message? = nil,
                            completion: @escaping CompletionResult<SuccessResponse>) {
        let task = ChangeFileSettingsTask(changes: changes)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// This command write all files provided in `files` to card.
    ///
    /// - Warning: This command available for COS 3.29 and higher
    /// - Note: Writing files protected by Passcode only available for COS 3.34 and higher
    /// - Parameters:
    ///   - files: List of files that should be written to card
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<WriteFilesResponse, TangemSdkError>`
    func writeFiles(files: [FileToWrite],
                    cardId: String? = nil,
                    initialMessage: Message? = nil,
                    completion: @escaping CompletionResult<WriteFilesResponse>) {
        let task = WriteFilesTask(files: files)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// This command deletes selected files from card. This operation can't be undone.
    ///
    /// To perform file deletion you should initially read all files (`readFiles` command) and add them to `indices` array. When files deleted from card, other files change their indexies.
    /// After deleting files you should additionally perform `readFiles` command to actualize files indices
    /// - Warning: This command available for COS 3.29 and higher
    /// - Parameters:
    ///   - indices: indices of files that should be deleteled. If nil - deletes all files from card
    ///   - cardId: CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SuccessResponse, TangemSdkError>`
    func deleteFiles(indices: [Int]?,
                     cardId: String? = nil,
                     initialMessage: Message? = nil,
                     completion: @escaping CompletionResult<SuccessResponse>) {
        let task = DeleteFilesTask(indices: indices)
        startSession(with: task, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// Creates hashes and signatures for files that signed by issuer
    /// - Parameters:
    ///     - cardId: CID, Unique Tangem card ID number.
    ///     - fileData: File data that will be written on card
    ///     - fileCounter:  A counter that protects issuer data against replay attack.
    ///     - fileName: Optional name of the file
    ///     - privateKey: Optional private key that will be used for signing files hashes. If it is provided, then  `FileHashData` will contain signed file signatures.
    /// - Returns:
    /// `FileHashData` with hashes to sign and signatures if `privateKey` was provided.
    func prepareHashes(cardId: String, fileData: Data, fileCounter: Int, fileName: String? = nil, privateKey: Data? = nil) throws -> FileHashData {
        return try FileHashHelper.prepareHash(for: cardId, fileData: fileData, fileCounter: fileCounter, fileName: fileName, privateKey: privateKey)
    }
    
    //MARK: - Issuer/User data
    
    /**
     * This command returns 512-byte Issuer Data field and its issuer’s signature.
     * Issuer Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. For example, this field may contain information about
     * wallet balance signed by the issuer or additional issuer’s attestation data.
     * - Parameters:
     *   - cardId: CID, Unique Tangem card ID number.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<ReadIssuerDataResponse,TangemSdkError>`
     */
    @available(*, deprecated, message: "Use files instead")
    func readIssuerData(cardId: String? = nil,
                        initialMessage: Message? = nil,
                        completion: @escaping CompletionResult<ReadIssuerDataResponse>) {
        startSession(with: ReadIssuerDataCommand(issuerPublicKey: config.issuerPublicKey),
                     cardId: cardId,
                     initialMessage: initialMessage,
                     completion: completion)
    }
    
    /**
     * This command writes 512-byte Issuer Data field and its issuer’s signature.
     * Issuer Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
     * format and payload of Issuer Data. For example, this field may contain information about
     * wallet balance signed by the issuer or additional issuer’s attestation data.
     * - Parameters:
     *   - issuerData: Data provided by issuer.
     *   - issuerDataSignature: Issuer’s signature of `issuerData` with Issuer Data Private Key (which is kept on card).
     *   - issuerDataCounter: An optional counter that protect issuer data against replay attack.
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<SuccessResponse,TangemSdkError>`
     */
    @available(*, deprecated, message: "Use files instead")
    func writeIssuerData(issuerData: Data,
                         issuerDataSignature: Data,
                         issuerDataCounter: Int? = nil,
                         cardId: String? = nil,
                         initialMessage: Message? = nil,
                         completion: @escaping CompletionResult<SuccessResponse>) {
        let command = WriteIssuerDataCommand(issuerData: issuerData,
                                             issuerDataSignature: issuerDataSignature,
                                             issuerDataCounter: issuerDataCounter,
                                             issuerPublicKey: config.issuerPublicKey)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    
    /// This task retrieves Issuer Extra Data field and its issuer’s signature.
    /// Issuer Extra Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
    /// format and payload of Issuer Data. . For example, this field may contain photo or
    /// biometric information for ID card product. Because of the large size of Issuer_Extra_Data,
    /// a series of these commands have to be executed to read the entire Issuer_Extra_Data.
    ///
    /// - Warning: This command is not supported for COS 3.29 and higher. Use files api instead
    /// - Parameters:
    ///   - cardId:  CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<ReadIssuerExtraDataResponse,TangemSdkError>`
    @available(*, deprecated, message: "Use files instead")
    func readIssuerExtraData(cardId: String? = nil,
                             initialMessage: Message? = nil,
                             completion: @escaping CompletionResult<ReadIssuerExtraDataResponse>) {
        let command = ReadIssuerExtraDataCommand(issuerPublicKey: config.issuerPublicKey)
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /// This task writes Issuer Extra Data field and its issuer’s signature.
    /// Issuer Extra Data is never changed or parsed from within the Tangem COS.
    /// The issuer defines purpose of use, format and payload of Issuer Data.
    /// For example, this field may contain a photo or biometric information for ID card products.
    /// Because of the large size of Issuer_Extra_Data, a series of these commands have to be executed
    /// to write entire Issuer_Extra_Data.
    ///
    /// - Warning: This command is not supported for COS 3.29 and higher. Use files api instead
    /// - Parameters:
    ///   - issuerData: Data provided by issuer.
    ///   - startingSignature: Issuer’s signature with Issuer Data Private Key of [cardId],
    ///   [issuerDataCounter] (if flags Protect_Issuer_Data_Against_Replay and
    ///   Restrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]) and size of [issuerData].
    ///   - finalizingSignature:  Issuer’s signature with Issuer Data Private Key of [cardId],
    ///   [issuerData] and [issuerDataCounter] (the latter one only if flags Protect_Issuer_Data_Against_Replay
    ///   and Restrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]).
    ///   - issuerDataCounter:  An optional counter that protect issuer data against replay attack.
    ///   - cardId:  CID, Unique Tangem card ID number.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: Returns `Swift.Result<SuccessResponse,TangemSdkError>`
    @available(*, deprecated, message: "Use files instead")
    func writeIssuerExtraData(issuerData: Data,
                              startingSignature: Data,
                              finalizingSignature: Data,
                              issuerDataCounter: Int? = nil,
                              cardId: String? = nil,
                              initialMessage: Message? = nil,
                              completion: @escaping CompletionResult<SuccessResponse>) {
        
        let command = WriteIssuerExtraDataCommand(issuerData: issuerData,
                                                  issuerPublicKey: config.issuerPublicKey,
                                                  startingSignature: startingSignature,
                                                  finalizingSignature: finalizingSignature,
                                                  issuerDataCounter: issuerDataCounter)
        
        startSession(with: command, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /**
     * This method launches a [ReadUserDataCommand]
     *
     * This command returns two up to 512-byte User_Data, User_Protected_Data and two counters User_Counter and
     * User_Protected_Counter fields.
     * User_Data and User_ProtectedData are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_Counter and User_ProtectedCounter are counters, that initial values can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * - Parameters:
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<ReadUserDataResponse,TangemSdkError>`
     */
    @available(*, deprecated, message: "Use files instead")
    func readUserData(cardId: String? = nil,
                      initialMessage: Message? = nil,
                      completion: @escaping CompletionResult<ReadUserDataResponse>) {
        startSession(with: ReadUserDataCommand(), cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /**
     * This method launches a [WriteUserDataCommand]
     *
     * This command writes some UserData, and UserCounter fields.
     * User_Data are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_Counter are counter, that initial value can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * Writing of UserCounter and UserData is protected only by Access Code.
     * - Parameters:
     *   - userData: Data defined by user’s App
     *   - userCounter: Counter initialized by user’s App and increased on every signing of new transaction.  If nil, the current counter value will not be overwritten.
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<SuccessResponse,TangemSdkError>`
     */
    @available(*, deprecated, message: "Use files instead")
    func writeUserData(userData: Data,
                       userCounter: Int? = nil,
                       cardId: String? = nil,
                       initialMessage: Message? = nil,
                       completion: @escaping CompletionResult<SuccessResponse>) {
        let writeUserDataCommand = WriteUserDataCommand(userData: userData, userCounter: userCounter)
        startSession(with: writeUserDataCommand, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
    
    /**
     * This method launches a [WriteUserDataCommand]
     *
     * This command writes some UserProtectedData and UserProtectedCounter fields.
     * User_ProtectedData are never changed or parsed by the executable code the Tangem COS.
     * The App defines purpose of use, format and it's payload. For example, this field may contain cashed information
     * from blockchain to accelerate preparing new transaction.
     * User_ProtectedCounter are counter, that initial value can be set by App and increased on every signing
     * of new transaction (on SIGN command that calculate new signatures). The App defines purpose of use.
     * For example, this fields may contain blockchain nonce value.
     *
     * UserProtectedCounter and UserProtectedData is protected by Access Code and need additionally Passcode to confirmation.
     * - Parameters:
     *   - userProtectedData: Data defined by user’s App (confirmed by Passcode)
     *   - userProtectedCounter: Counter initialized by user’s App (confirmed by Passcode) and increased on every signing of new transaction.  If nil, the current counter value will not be overwritten.
     *   - cardId:  CID, Unique Tangem card ID number.
     *   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
     *   - completion: Returns `Swift.Result<SuccessResponse,TangemSdkError>`
     */
    @available(*, deprecated, message: "Use files instead")
    func writeUserProtectedData(userProtectedData: Data,
                                userProtectedCounter: Int? = nil,
                                cardId: String? = nil,
                                initialMessage: Message? = nil,
                                completion: @escaping CompletionResult<SuccessResponse>) {
        let writeUserDataCommand = WriteUserDataCommand(userProtectedData: userProtectedData, userProtectedCounter: userProtectedCounter)
        startSession(with: writeUserDataCommand, cardId: cardId, initialMessage: initialMessage, completion: completion)
    }
}

//MARK: - Session start
extension TangemSdk {
    /// Allows running a custom bunch of commands in one NFC Session by creating a custom task. Tangem SDK will start a card session, perform preflight `Read` command,
    /// invoke the `run ` method of `CardSessionRunnable` and close the session.
    /// You can find the current card in the `environment` property of the `CardSession`
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - completion: Standart completion handler. Invoked on the main thread. `(Swift.Result<CardSessionRunnable.Response, TangemSdkError>) -> Void`.
    public func startSession<T>(with runnable: T,
                                completion: @escaping CompletionResult<T.Response>)
    where T : CardSessionRunnable {
        do {
            try checkSession()
        } catch {
            completion(.failure(error.toTangemSdkError()))
            return
        }

        configure()
        cardSession = makeSession(with: config,
                                  filter: nil,
                                  initialMessage: nil,
                                  accessCode: nil)
        cardSession!.start(with: runnable, completion: completion)
    }

    /// Allows running a custom bunch of commands in one NFC Session by creating a custom task. Tangem SDK will start a card session, perform preflight `Read` command,
    /// invoke the `run ` method of `CardSessionRunnable` and close the session.
    /// You can find the current card in the `environment` property of the `CardSession`
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - filter: Filters card to be read. Optional.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used.
    ///   - accessCode: Access code that will be used for a card session initialization. If nil, Tangem SDK will handle it automatically.
    ///   - completion: Standart completion handler. Invoked on the main thread. `(Swift.Result<CardSessionRunnable.Response, TangemSdkError>) -> Void`.
    public func startSession<T>(with runnable: T,
                                filter: SessionFilter?,
                                initialMessage: Message? = nil,
                                accessCode: String? = nil,
                                completion: @escaping CompletionResult<T.Response>)
    where T : CardSessionRunnable {
        do {
            try checkSession()
        } catch {
            completion(.failure(error.toTangemSdkError()))
            return
        }

        configure()
        cardSession = makeSession(with: config,
                                  filter: filter,
                                  initialMessage: initialMessage,
                                  accessCode: accessCode)
        cardSession!.start(with: runnable, completion: completion)
    }

    /// Allows running a custom bunch of commands in one NFC Session by creating a custom task. Tangem SDK will start a card session, perform preflight `Read` command,
    /// invoke the `run ` method of `CardSessionRunnable` and close the session.
    /// You can find the current card in the `environment` property of the `CardSession`
    /// - Parameters:
    ///   - runnable: A custom task, adopting `CardSessionRunnable` protocol
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the card with this cardID and will return the `wrongCard` error otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used.
    ///   - accessCode: Access code that will be used for a card session initialization. If nil, Tangem SDK will handle it automatically.
    ///   - completion: Standard completion handler. Invoked on the main thread. `(Swift.Result<CardSessionRunnable.Response, TangemSdkError>) -> Void`.
    public func startSession<T>(with runnable: T,
                                cardId: String? = nil,
                                initialMessage: Message? = nil,
                                accessCode: String? = nil,
                                completion: @escaping CompletionResult<T.Response>)
    where T : CardSessionRunnable {
        startSession(with: runnable,
                     filter: .init(from: cardId),
                     initialMessage: initialMessage,
                     accessCode: accessCode,
                     completion: completion)
    }
    
    /// Allows running  a custom bunch of commands in one NFC Session with lightweight closure syntax. Tangem SDK will start a card sesion and perform preflight `Read` command.
    /// - Parameters:
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - accessCode: Access code that will be used for a card session initialization. If nil, Tangem SDK will handle it automatically.
    ///   - callback: At first, you should check that the `TangemSdkError` is not nil, then you can use the `CardSession` to interact with a card.
    ///   You can find the current card in the `environment` property of the `CardSession`
    ///   If you need to interact with UI, you should dispatch to the main thread manually
    public func startSession(cardId: String? = nil,
                             initialMessage: Message? = nil,
                             accessCode: String? = nil,
                             callback: @escaping (CardSession, TangemSdkError?) -> Void) {
        do {
            try checkSession()
        } catch {
            callback(cardSession!, error.toTangemSdkError())
            return
        }
        
        configure()
        cardSession = makeSession(with: config,
                                  filter: .init(from: cardId),
                                  initialMessage: initialMessage,
                                  accessCode: accessCode)
        cardSession?.start(callback)
    }
    
    /// Allows running a custom bunch of commands in one NFC Session by creating a custom task. Tangem SDK will start a card session, perform preflight `Read` command,
    /// invoke the `run ` method of `CardSessionRunnable` and close the session.
    /// You can find the current card in the `environment` property of the `CardSession`
    /// - Parameters:
    ///   - jsonRequest: A JSONRPCRequest, describing specific`CardSessionRunnable`
    ///   - cardId: CID, Unique Tangem card ID number. If not nil, the SDK will check that you tapped the  card with this cardID and will return the `wrongCard` error' otherwise
    ///   - accessCode: Access code that will be used for a card session initialization. If nil, Tangem SDK will handle it automatically.
    ///   - initialMessage: A custom description that shows at the beginning of the NFC session. If nil, default message will be used
    ///   - completion: A JSONRPCResponse with with result of the operation
    public func startSession(with jsonRequest: String,
                             cardId: String? = nil,
                             initialMessage: String? = nil,
                             accessCode: String? = nil,
                             completion: @escaping (String) -> Void) {

        do {
            let parseResult = try JSONRPCRequestParser().parse(jsonString: jsonRequest)
            let runnables = try parseResult.requests.map { try jsonConverter.convert(request: $0) }
            
            try checkSession()
            configure()
            cardSession = makeSession(with: config,
                                      filter: .init(from: cardId),
                                      initialMessage: initialMessage.flatMap { Message($0) },
                                      accessCode: accessCode)
            
            let task = RunnablesTask(runnables: runnables)
            cardSession!.start(with: task) { result in
                switch result {
                case .success(let response):
                    switch parseResult {
                    case .array:
                        completion(response.json)
                    case .single:
                        if response.count == 1 {
                            completion(response[0].json)
                        } else {
                            completion(TangemSdkError.unknownError.toJsonResponse().json)
                        }
                    }
                case .failure(let error):
                    completion(error.toJsonResponse().json)
                }
            }
        } catch {
            completion(error.toJsonResponse().json)
        }
    }
}

//MARK: - Private
extension TangemSdk {
    private func checkSession() throws {
        if let existingSession = cardSession, existingSession.state == .active  {
            throw TangemSdkError.busy
        }
    }
    
    private func configure() {
        Log.config = config.logConfig
    }
    
    private func makeAccessCodeRepository(with config: Config) -> AccessCodeRepository? {
        if case .alwaysWithBiometrics = config.accessCodeRequestPolicy,
           BiometricsUtil.isAvailable {
            return AccessCodeRepository()
        }

        Log.debug("Failed to initialize AccessCodeRepository. Biometrics is unavailable.")
        
        return nil
    }
    
    func makeSession(with config: Config,
                     filter: SessionFilter?,
                     initialMessage: Message?,
                     accessCode: String? = nil) -> CardSession {
        var env = SessionEnvironment(config: config, terminalKeysService: terminalKeysService)
        
        if let accessCode = accessCode {
            env.accessCode = .init(.accessCode, stringValue: accessCode)
        }
        
        return CardSession(environment: env,
                           filter: filter,
                           initialMessage: initialMessage,
                           cardReader: reader,
                           viewDelegate: viewDelegate,
                           jsonConverter: jsonConverter,
                           accessCodeRepository: makeAccessCodeRepository(with: config))
    }
}
