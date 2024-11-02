//
//  TangemSdkError.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.03.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC

/**
 * An error class that represent typical errors that may occur when performing Tangem SDK tasks.
 * Errors are propagated back to the caller in callbacks.
 */
public enum TangemSdkError: Error, LocalizedError, Encodable {
    //MARK: NFC processing errors
    
    /// Command was sent to wrong tag type
    case unsupportedCommand
    
    /// This error is returned when the current device doesn't support the desired NFC operations
    case unsupportedDevice
    
    /// Start session before
    case sessionInactive
    
    /// It seems that NFC does not work properly on your iPhone. Try to reboot your iPhone
    case nfcStuck
    
    case nfcTimeout
    
    case nfcReaderError
    
    
    //MARK: Apdu processing errrors
    
    case serializeCommandError
    
    /// This error is returned when the `ResponseApdu` cannot deserialize bytes to `[Tlv]`
    case deserializeApduFailed
    
    /// This error is returned when the `TlvEncoder` failed to encode value not matching `TlvTag` value type
    case encodingFailedTypeMismatch(_ message: String)
    
    /// This error is returned when the `TlvEncoder` failed to encode nil value or failed to encode stiring with utf8 encoding
    case encodingFailed(_ message: String)
    
    /// This error is returned when the `TlvDecoder` cannot find desired tag. You can use `decode` to handle this error automatically
    case decodingFailedMissingTag(_ message: String)
    
    /// This error is returned when the `TlvDecoder` failed to decode value not matching `TlvTag` value type
    case decodingFailedTypeMismatch(_ message: String)
    
    /// This error is returned when the `TlvDecoder` failed to decode value. Please let us know
    case decodingFailed(_ message: String)
    
    case failedToEncryptApdu
    
    case failedToDecryptApdu
    
    case failedToEstablishEncryption
    
    case invalidResponseApdu
    
    case failedToBuildCommandApdu
    
    //MARK: Card errors
    
    /// This error is returned when unknown `StatusWord` is received from a card.
    case unknownStatus(_ sw: String)
    
    /// This error is returned when a card's reply is `StatusWord.ErrorProcessingCommand`.
    /// The card sends this status in case of internal card error
    case errorProcessingCommand
    
    /// This error is returned when a card's reply is `StatusWord.InvalidState`.
    /// The card sends this status when command can not be executed in the current state of a card.
    case invalidState
    
    /// This error is returned when a card's reply is `StatusWord.InsNotSupported`.
    /// The card sends this status when the card cannot process the `Instruction`.
    case insNotSupported
    
    /// This error is returned when a card's reply is `StatusWord.InvalidParams`.
    /// The card sends this status when there are wrong or not sufficient parameters in `TLV` request, or wrong `PIN1/PIN2`.
    /// The error may be caused, for example, by wrong parameters of the `ApduSerializable`, encode/decode  errors.
    case invalidParams
    
    /// This error is returned when a card's reply is `StatusWord.NeedEncryption` and the encryption was not established by TangemSdk.
    case needEncryption
    
    
    //MARK: Business logic errors
    
    // Personalization Errors
    case alreadyPersonalized
    
    // Depersonalization Errors
    case cannotBeDepersonalized
    
    // Read Errors
    case accessCodeRequired
    case nonHardenedDerivationNotSupported
    
    // CreateWallet Errors
    case alreadyCreated
    case unsupportedCurve //todo: localize
    case unsupportedWalletConfig //todo: localize
    
    // PurgeWallet Errors
    case purgeWalletProhibited
    
    // SetPin Errors
    case accessCodeCannotBeChanged
    case passcodeCannotBeChanged
    case accessCodeCannotBeDefault
    case passcodeCannotBeDefault
    case accessCodeTooShort
    case passcodeTooShort
    
    //Sign Errors
    case noRemainingSignatures
    case oldCard
    
    /// This error is returned when a `SignCommand` receives only empty hashes for signature.
    case emptyHashes

    case signHashesNotAvailable
    
    // Write Extra Issuer Data Errors
    case extendedDataSizeTooLarge
    
    // General Errors
    
    case notPersonalized
    
    case notActivated
    
    case walletIsPurged
    
    case passcodeRequired
    
    /// This error is returned when SDK checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case verificationFailed
    
    case cardVerificationFailed
    
    /// This error is returned when a [Task] checks unsuccessfully either
    /// a card's ability to sign with its private key, or the validity of issuer data.
    case dataSizeTooLarge
    
    /// This error is returned when `ReadIssuerData` or `ReadIssuerExtraData` expects a counter
    /// (when the card's requires it), but the counter is missing.
    case missingCounter
    
    case overwritingDataIsProhibited
    
    case dataCannotBeWritten
    
    /// This error is returned when `issuerPublicKey` requires to perform operation
    case missingIssuerPublicKey
    
    ///User entered wrong Access Code
    case wrongAccessCode
    
    ///User entered wrong Passcode
    case wrongPasscode
    
    //MARK: SDK errors
    
    case unknownError
    
    case underlying(error: Error)
    
    /// This error is returned when a user manually closes the NFC  Dialog.
    case userCancelled
    
    case userForgotTheCode
    
    case biometricsUnavailable
    
    /// This error is returned when `CardSession`  was called with a new operation,  while a previous operation is still in progress.
    case busy
    
    /// This error is returned when a `CardSessionRunnable` requires that `ReadCommand`
    /// is executed before performing other commands.
    case missingPreflightRead
    
    /// This error is returned when a [Task] expects a user to use a particular card,
    /// but the user tries to use a different card.
    case wrongCardNumber(expectedCardId: String?)
    
    /// This error is returned when a user scans a card of a [com.tangem.common.extensions.CardType]
    /// that is not specified in [Config.cardFilter].
    case wrongCardType(_ localizedDescription: String?)

    case preflightFiltered(_ error: Error)

    /// This error is returned when the scanned card doesn't have some essential fields.
    case cardError
    
    /// This error is returned when SDK fails to perform some low-level crypto algorithm
    case cryptoUtilsError(_ message: String)
    
    /// This error is returned when the error occurs inside third-party crypto libraries code
    case failedToGenerateRandomSequence
    
    //MARK: Underlying NFC reader errors
    case readerErrorUnsupportedFeature
    case readerErrorSecurityViolation
    case readerErrorInvalidParameter
    case readerErrorInvalidParameterLength
    case readerErrorParameterOutOfBound
    case readerTransceiveErrorTagConnectionLost
    case readerTransceiveErrorRetryExceeded
    case readerTransceiveErrorTagResponseError
    case readerTransceiveErrorSessionInvalidated
    case readerTransceiveErrorTagNotConnected
    case readerSessionInvalidationErrorSessionTimeout
    case readerSessionInvalidationErrorSessionTerminatedUnexpectedly
    case readerSessionInvalidationErrorFirstNDEFTagRead
    case tagCommandConfigurationErrorInvalidParameters
    case ndefReaderSessionErrorTagNotWritable
    case ndefReaderSessionErrorTagUpdateFailure
    case ndefReaderSessionErrorTagSizeTooSmall
    case ndefReaderSessionErrorZeroLengthMessage
    case readerErrorRadioDisabled
    case readerTransceiveErrorPacketTooLong
    
    // MARK: Files errors
    
    /// Returned when there is no files on card or when successfully read all files
    case fileNotFound
    case fileSettingsUnsupported
    case filesIsEmpty
    
    /// Returned when command setup not available interaction mode (ex. while writing file was setup delete interaction mode)
    case wrongInteractionMode
    
    /// Returned when command  is not met firmware version requirements (ex. for file writing COD must be 3.29 or greater)
    case notSupportedFirmwareVersion
    
    // MARK: Wallet errors
    case maxNumberOfWalletsCreated
    case walletNotFound
    case cardWithMaxZeroWallets
    case walletCannotBeCreated
    case walletAlreadyCreated
    
    // MARK: Backup errors
    case backupFailedCardNotLinked
    case backupNotAllowed
    case backupCardAlreadyAdded
    case missingPrimaryCard
    case missingPrimaryAttestSignature
    case tooMuchBackupCards
    case backupCardRequired
    case noBackupDataForCard
    case backupFailedEmptyWallets
    case backupFailedNotEmptyWallets(cardId: String)
    case certificateSignatureRequired
    case issuerSignatureLoadingFailed
    case accessCodeOrPasscodeRequired
    case noActiveBackup
    case resetBackupFailedHasBackedUpWallets
    case backupServiceInvalidState
    case noBackupCardForIndex
    case emptyBackupCards
    case backupFailedWrongIssuer
    case backupFailedHDWalletSettings
    case backupFailedNotEnoughCurves
    case backupFailedNotEnoughWallets
    case backupFailedFirmware
    case backupFailedIncompatibleBatch
    case backupFailedIncompatibleFirmware
    case backupFailedKeysImportSettings
    case backupFailedAlreadyCreated

    //MARK: Settings
    case filesDisabled
    case hdWalletDisabled
    case keysImportDisabled
    case userCodeRecoveryDisabled
    
    case resetPinNoCardToReset
    case resetPinWrongCard(internalCode: Int? = nil)
    
    public var code: Int {
        switch self {
            // MARK: 1xxxx Errors
        case .unsupportedCommand: return 10003
        case .unsupportedDevice: return 10004
        case .sessionInactive: return 10005
        case .nfcStuck: return 10006
        case .nfcTimeout: return 10007
        case .nfcReaderError: return 10008
            
            
            // MARK: 2xxxx Errors
            // Errors occured during the mapping or parsing data.
        case .serializeCommandError: return 20001
        case .deserializeApduFailed: return 20002
        case .encodingFailedTypeMismatch: return 20003
        case .encodingFailed: return 20004
        case .decodingFailedMissingTag: return 20005
        case .decodingFailedTypeMismatch: return 20006
        case .decodingFailed: return 20007
        case .failedToEncryptApdu: return 20008
        case .failedToDecryptApdu: return 20009
        case .failedToEstablishEncryption: return 20010
        case .invalidResponseApdu: return 20011
        case .failedToBuildCommandApdu: return 20012
            
            // MARK: 3xxxx Errors
            // Errors from card SW codes
        case .unknownStatus: return 30001
        case .errorProcessingCommand: return 30002
        case .invalidState: return 30003
        case .insNotSupported: return 30004
        case .invalidParams: return 30005
        case .needEncryption: return 30006
        case .fileNotFound: return 30007
        case .walletNotFound: return 30008
            
            // MARK: 4yyxx Errors
            // Command Error. Business logical errors that occurred inside commands' implmentation.
            
        case .notPersonalized: return 40001
        case .notActivated: return 40002
        case .walletIsPurged: return 40003
        case .passcodeRequired: return 40004
        case .verificationFailed: return 40005
        case .dataSizeTooLarge: return 40006
        case .missingCounter: return 40007
        case .overwritingDataIsProhibited: return 40008
        case .dataCannotBeWritten: return 40009
        case .missingIssuerPublicKey: return 40010
        case .cardVerificationFailed: return 40011
        case .wrongAccessCode: return 40012
        case .wrongPasscode: return 40013
            
        case .alreadyPersonalized: return 40101
            
        case .cannotBeDepersonalized: return 40201
            
        case .accessCodeRequired: return 40401
        case .nonHardenedDerivationNotSupported: return 40402
        case .walletCannotBeCreated: return 40403
        case .cardWithMaxZeroWallets: return 40404
        case .walletAlreadyCreated: return 40405
            
        case .alreadyCreated: return 40501
        case .unsupportedCurve: return 40502
        case .maxNumberOfWalletsCreated: return 40503
        case .unsupportedWalletConfig: return 40504
            
        case .purgeWalletProhibited: return 40601
            
        case .accessCodeCannotBeChanged: return 40801
        case .passcodeCannotBeChanged: return 40802
        case .accessCodeCannotBeDefault: return 40803
        case .passcodeCannotBeDefault: return 40804
        case .accessCodeTooShort: return 40805
        case .passcodeTooShort: return 40806
            
        case .noRemainingSignatures: return 40901
        case .emptyHashes: return 40902
        case .signHashesNotAvailable: return 40905
        case .oldCard: return 40907
            
        case .extendedDataSizeTooLarge: return 41101
            
        case .backupFailedCardNotLinked: return 41201
        case .backupCardAlreadyAdded: return 41202
        case .missingPrimaryCard: return 41203
        case .backupNotAllowed: return 41204
        case .missingPrimaryAttestSignature: return 41205
        case .tooMuchBackupCards: return 41206
        case .backupCardRequired: return 41207
        case .noBackupDataForCard: return 41208
        case .backupFailedEmptyWallets: return 41209
        case .backupFailedNotEmptyWallets: return 41210
        case .certificateSignatureRequired: return 41211
        case .accessCodeOrPasscodeRequired: return 41212
        case .noActiveBackup: return 41220
        case .resetBackupFailedHasBackedUpWallets: return 41221
        case .backupServiceInvalidState: return 41222
        case .noBackupCardForIndex: return 41223
        case .emptyBackupCards: return 41224
        case .backupFailedWrongIssuer: return 41225
        case .backupFailedHDWalletSettings: return 41226
        case .backupFailedNotEnoughCurves: return 41227
        case .backupFailedNotEnoughWallets: return 41228
        case .issuerSignatureLoadingFailed: return 41229
        case .backupFailedFirmware: return 41230
        case .backupFailedIncompatibleBatch: return 41231
        case .backupFailedIncompatibleFirmware: return 41232
        case .backupFailedKeysImportSettings: return 41233
        case .backupFailedAlreadyCreated: return 41234
            
        case .resetPinNoCardToReset: return 41300
        case .resetPinWrongCard(let internalCode): return internalCode ?? 41301
            
        case .fileSettingsUnsupported: return 42000
        case .filesIsEmpty: return 42001
            
        case .filesDisabled: return 42002
        case .hdWalletDisabled: return 42003
        case .keysImportDisabled: return 42004
        case .userCodeRecoveryDisabled: return 42005
            
            // MARK: 5xxxx Errors
            // SDK error. Errors, that occurred in the upper level of SDK, like device restrictions, user canceled the operation or SDK is busy and can’t open the new session right now.
        case .unknownError: return 50001
        case .userCancelled: return 50002
        case .busy: return 50003
        case .missingPreflightRead: return 50004
        case .wrongCardNumber: return 50005
        case .wrongCardType: return 50006
        case .cardError: return 50007
        case .notSupportedFirmwareVersion: return 50008
        case .failedToGenerateRandomSequence: return 50010
        case .cryptoUtilsError: return 50011
        case .underlying: return 50012
        case .userForgotTheCode: return 50013
        case .biometricsUnavailable: return 50014
        case .preflightFiltered: return 50015

        case .wrongInteractionMode: return 50027
            
            // MARK: 9xxxx Errors
            // Reader error.
            
        case .readerErrorUnsupportedFeature: return 90003
        case .readerErrorSecurityViolation: return 90004
        case .readerErrorInvalidParameter: return 90005
        case .readerErrorInvalidParameterLength: return 90006
        case .readerErrorParameterOutOfBound: return 90007
        case .readerTransceiveErrorTagConnectionLost: return 90008
        case .readerTransceiveErrorRetryExceeded: return 90009
        case .readerTransceiveErrorTagResponseError: return 90010
        case .readerTransceiveErrorSessionInvalidated: return 90011
        case .readerTransceiveErrorTagNotConnected: return 90012
        case .readerSessionInvalidationErrorSessionTimeout: return 90013
        case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly: return 90014
        case .readerSessionInvalidationErrorFirstNDEFTagRead: return 90015
        case .tagCommandConfigurationErrorInvalidParameters: return 90016
        case .ndefReaderSessionErrorTagNotWritable: return 90017
        case .ndefReaderSessionErrorTagUpdateFailure: return 90018
        case .ndefReaderSessionErrorTagSizeTooSmall: return 90019
        case .ndefReaderSessionErrorZeroLengthMessage: return 90020
        case .readerErrorRadioDisabled: return 90021
        case .readerTransceiveErrorPacketTooLong: return 90022
        }
    }
    
    public var message: String? {
        switch self {
        case .encodingFailed(let message):
            return message
        case .encodingFailedTypeMismatch(let message):
            return message
        case .decodingFailed(let message):
            return message
        case .decodingFailedTypeMismatch(let message):
            return message
        case .decodingFailedMissingTag(let message):
            return message
        default:
            return nil
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .nfcTimeout: return "nfc_session_timeout".localized
        case .nfcStuck: return "nfc_stuck_error".localized
        case .alreadyCreated: return "error_already_created".localized
        case .accessCodeCannotBeChanged: return "error_pin_cannot_be_changed_format".localized(UserCodeType.accessCode.name)
        case .passcodeCannotBeChanged: return "error_pin_cannot_be_changed_format".localized(UserCodeType.passcode.name)
        case .accessCodeCannotBeDefault: return "error_pin_cannot_be_default_format".localized(UserCodeType.accessCode.name)
        case .passcodeCannotBeDefault: return "error_pin_cannot_be_default_format".localized(UserCodeType.passcode.name)
        case .accessCodeTooShort: return String(format: "error_pin_too_short_format".localized, UserCodeType.accessCode.name, UserCodeType.minLength)
        case .passcodeTooShort: return String(format: "error_pin_too_short_format".localized, UserCodeType.passcode.name, UserCodeType.minLength)
        case .purgeWalletProhibited: return "error_purge_prohibited".localized
        case .userCancelled: return "error_user_cancelled".localized
        case .cardVerificationFailed: return "error_card_verification_failed".localized
        case .wrongCardNumber(let expectedCardId):
            if let expectedCardId {
                return "error_wrong_card_number_with_card_id".localized(expectedCardId)
            } else {
                return "error_wrong_card_number_without_card_id".localized
            }
        case .wrongCardType(let localizedDescription): return localizedDescription ?? "error_wrong_card_type".localized
        case .accessCodeRequired: return "error_pin_required_format".localized(UserCodeType.accessCode.name)
        case .passcodeRequired: return "error_pin_required_format".localized(UserCodeType.passcode.name)
        case .underlying(let error), .preflightFiltered(let error): return error.localizedDescription
        case .fileNotFound: return "error_file_not_found".localized
        case .walletNotFound: return "wallet_not_found".localized
        case .wrongAccessCode: return "error_wrong_pin_format".localized(UserCodeType.accessCode.name)
        case .wrongPasscode: return "error_wrong_pin_format".localized(UserCodeType.passcode.name)
        case .issuerSignatureLoadingFailed: return "issuer_signature_loading_failed".localized
        case .backupCardRequired, .backupCardAlreadyAdded: return "error_backup_card_already_added".localized
        case .backupFailedNotEmptyWallets: return "error_backup_not_empty_wallets".localized
        case .backupFailedWrongIssuer, .backupFailedHDWalletSettings, .backupFailedNotEnoughCurves,
                .backupFailedNotEnoughWallets, .backupFailedFirmware, .backupNotAllowed,
                .backupFailedIncompatibleBatch, .backupFailedIncompatibleFirmware, .backupFailedKeysImportSettings:
            return "error_backup_wrong_card".localized("\(self.code)")
        case .backupFailedAlreadyCreated:
            return "error_backup_failed_already_created".localized
        case .resetPinWrongCard(let internalCode):
            switch internalCode {
            case TangemSdkError.noActiveBackup.code:
                return "error_no_active_backup".localized
            default:
                return "error_reset_wrong_card".localized("\(self.code)")
            }
        case .oldCard: return "error_old_card".localized
        case .userCodeRecoveryDisabled: return "error_user_code_recovery_disabled".localized
            
        default:
            if let message = self.message {
                return "generic_error_code".localized("\(self.code). \(message)")
            }
            
            //let description = "\(self)".capitalizingFirst()
            return "generic_error_code".localized("\(self.code)")
        }
    }
    
    public var jsonDescription: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
    
    public var isUserCancelled: Bool {
        if case .userCancelled = self {
            return true
        } else {
            return false
        }
    }
    
    public static func parse(_ error: Error) -> TangemSdkError {
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                return .userCancelled
            case .readerSessionInvalidationErrorSystemIsBusy:
                return .nfcStuck
            case .readerErrorUnsupportedFeature:
                return .readerErrorUnsupportedFeature
            case .readerErrorSecurityViolation:
                return .readerErrorSecurityViolation
            case .readerErrorInvalidParameter:
                return .readerErrorInvalidParameter
            case .readerErrorInvalidParameterLength:
                return .readerErrorInvalidParameterLength
            case .readerErrorParameterOutOfBound:
                return readerErrorParameterOutOfBound
            case .readerTransceiveErrorTagConnectionLost:
                return .readerTransceiveErrorTagConnectionLost
            case .readerTransceiveErrorRetryExceeded:
                return .readerTransceiveErrorRetryExceeded
            case .readerTransceiveErrorTagResponseError:
                return .readerTransceiveErrorTagResponseError
            case .readerTransceiveErrorSessionInvalidated:
                return .readerTransceiveErrorSessionInvalidated
            case .readerTransceiveErrorTagNotConnected:
                return .readerTransceiveErrorTagNotConnected
            case .readerSessionInvalidationErrorSessionTimeout:
                return readerSessionInvalidationErrorSessionTimeout
            case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                return .readerSessionInvalidationErrorSessionTerminatedUnexpectedly
            case .readerSessionInvalidationErrorFirstNDEFTagRead:
                return .readerSessionInvalidationErrorFirstNDEFTagRead
            case .tagCommandConfigurationErrorInvalidParameters:
                return .tagCommandConfigurationErrorInvalidParameters
            case .ndefReaderSessionErrorTagNotWritable:
                return .ndefReaderSessionErrorTagNotWritable
            case .ndefReaderSessionErrorTagUpdateFailure:
                return .ndefReaderSessionErrorTagUpdateFailure
            case .ndefReaderSessionErrorTagSizeTooSmall:
                return .ndefReaderSessionErrorTagSizeTooSmall
            case .ndefReaderSessionErrorZeroLengthMessage:
                return .ndefReaderSessionErrorZeroLengthMessage
            case .readerErrorRadioDisabled:
                return .readerErrorRadioDisabled
            case .readerTransceiveErrorPacketTooLong:
                return .readerTransceiveErrorPacketTooLong
            @unknown default:
                return .nfcReaderError
            }
        } else {
            return (error as? TangemSdkError) ?? TangemSdkError.underlying(error: error)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var error = [String:String]()
        error["code"] = String(describing: code)
        error["localizedDescription"] = localizedDescription
        var container = encoder.singleValueContainer()
        try container.encode(error)
    }
    
    /// Get error according to the pin type
    /// - Parameters:
    ///   - userCodeType: Specific user code type
    ///   - environment: optional environment. If set, a more specific error will be returned based on previous pin attempts during the session
    /// - Returns: TangemSdkError
    static func from(userCodeType: UserCodeType, environment: SessionEnvironment?) -> TangemSdkError {
        let isCodeSet = environment?.isUserCodeSet(userCodeType) ?? false
        
        switch userCodeType {
        case .accessCode:
            return isCodeSet ? .wrongAccessCode : .accessCodeRequired
        case .passcode:
            return isCodeSet ? .wrongPasscode : .passcodeRequired
        }
    }
}
