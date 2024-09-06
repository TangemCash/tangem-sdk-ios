//
//  Handlers.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class ScanHandler: JSONRPCHandler {
    var method: String { "SCAN" }
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = ScanTask()
        return command.eraseToAnyRunnable()
    }
}

class SignHashesHandler: JSONRPCHandler {
    var method: String { "SIGN_HASHES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let hashes: [Data] = try parameters.value(for: "hashes")
        
        let derivationRawPath: String? = try parameters.value(for: "derivationPath")
        let derivationPath: DerivationPath? = try derivationRawPath.map{ try DerivationPath(rawPath: $0) }
        
        let command = SignHashesCommand(hashes: hashes,
                                        walletPublicKey: walletPublicKey,
                                        derivationPath: derivationPath)
        return command.eraseToAnyRunnable()
    }
}

class SignHashHandler: JSONRPCHandler {
    var method: String { "SIGN_HASH" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let hash: Data = try parameters.value(for: "hash")
        
        let derivationRawPath: String? = try parameters.value(for: "derivationPath")
        let derivationPath: DerivationPath? = try derivationRawPath.map{ try DerivationPath(rawPath: $0) }
        
        let command = SignHashCommand(hash: hash,
                                      walletPublicKey: walletPublicKey,
                                      derivationPath: derivationPath)
        return command.eraseToAnyRunnable()
    }
}

class CreateWalletHandler: JSONRPCHandler {
    var method: String { "CREATE_WALLET" }

    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let curve: EllipticCurve = try parameters.value(for: "curve")
        let command = CreateWalletTask(curve: curve)
        return command.eraseToAnyRunnable()
    }
}

class ImportWalletHandler: JSONRPCHandler {
    var method: String { "IMPORT_WALLET" }

    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let curve: EllipticCurve = try parameters.value(for: "curve")
        let mnemonicString: String = try parameters.value(for: "mnemonic")
        let passphrase: String = try parameters.value(for: "passphrase") ?? ""

        let mnemonic = try Mnemonic(with: mnemonicString)
        let factory = AnyMasterKeyFactory(mnemonic: mnemonic, passphrase: passphrase)
        let privateKey = try factory.makeMasterKey(for: curve)
        let command = CreateWalletTask(curve: curve, privateKey: privateKey)
        return command.eraseToAnyRunnable()
    }
}

class PurgeWalletHandler: JSONRPCHandler {
    var method: String { "PURGE_WALLET" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let command = PurgeWalletCommand(publicKey: walletPublicKey)
        return command.eraseToAnyRunnable()
    }
}

class PersonalizeHandler: JSONRPCHandler {
    var method: String { "PERSONALIZE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let config: CardConfig = try parameters.value(for: "config")
        let issuer: Issuer = try parameters.value(for: "issuer")
        let manufacturer: Manufacturer = try parameters.value(for: "manufacturer")
        let acquirer: Acquirer = try parameters.value(for: "acquirer")
        
        let command = PersonalizeCommand(config: config,
                                         issuer: issuer,
                                         manufacturer: manufacturer,
                                         acquirer: acquirer)
        return command.eraseToAnyRunnable()
    }
}

class DepersonalizeHandler: JSONRPCHandler {
    var method: String { "DEPERSONALIZE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = DepersonalizeCommand()
        return command.eraseToAnyRunnable()
    }
}

class SetAccessCodeHandler: JSONRPCHandler {
    var method: String { "SET_ACCESSCODE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let accessCode: String? = try parameters.value(for: "accessCode")
        let command = SetUserCodeCommand(accessCode: accessCode)
        return command.eraseToAnyRunnable()
    }
}

class SetPasscodeHandler: JSONRPCHandler {
    var method: String { "SET_PASSCODE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let passcode: String? = try parameters.value(for: "passcode")
        let command = SetUserCodeCommand(passcode: passcode)
        return command.eraseToAnyRunnable()
    }
}

class ResetUserCodesHandler: JSONRPCHandler {
    var method: String { "RESET_USERCODES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        return SetUserCodeCommand.resetUserCodes.eraseToAnyRunnable()
    }
}

class ReadFilesHandler: JSONRPCHandler {
    var method: String { "READ_FILES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let readPrivateFiles: Bool? = try parameters.value(for: "readPrivateFiles")
        let fileName: String? = try parameters.value(for: "fileName")
        let walletPublicKey: Data? = try parameters.value(for: "walletPublicKey")
        
        let task = ReadFilesTask(fileName: fileName, walletPublicKey: walletPublicKey)
        readPrivateFiles.map { task.shouldReadPrivateFiles = $0 }
        
        return task.eraseToAnyRunnable()
    }
}

class WriteFilesHandler: JSONRPCHandler {
    var method: String { "WRITE_FILES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let files: [FileToWrite] = try parameters.value(for: "files")
        let command = WriteFilesTask(files: files)
        return command.eraseToAnyRunnable()
    }
}

class DeleteFilesHandler: JSONRPCHandler {
    var method: String { "DELETE_FILES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let indices: [Int]? = try parameters.value(for: "indices")
        let command = DeleteFilesTask(indices: indices)
        return command.eraseToAnyRunnable()
    }
}

class ChangeFileSettingsHandler: JSONRPCHandler {
    var method: String { "CHANGE_FILE_SETTINGS" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let changes: [Int: FileVisibility] = try parameters.value(for: "changes")
        let command = ChangeFileSettingsTask(changes: changes)
        return command.eraseToAnyRunnable()
    }
}

class DeriveWalletPublicKeyHandler: JSONRPCHandler {
    var method: String { "DERIVE_WALLET_PUBLIC_KEY" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let rawDerivationPath: String = try parameters.value(for: "derivationPath")
        let derivationPath: DerivationPath = try DerivationPath(rawPath: rawDerivationPath)
        
        let command = DeriveWalletPublicKeyTask(walletPublicKey: walletPublicKey,
                                                derivationPath: derivationPath)
        return command.eraseToAnyRunnable()
    }
}

class DeriveWalletPublicKeysHandler: JSONRPCHandler {
    var method: String { "DERIVE_WALLET_PUBLIC_KEYS" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletPublicKey: Data = try parameters.value(for: "walletPublicKey")
        let rawDerivationPaths: [String] = try parameters.value(for: "derivationPaths")
        let derivationPaths: [DerivationPath] = try rawDerivationPaths.map { try DerivationPath(rawPath: $0) }
        
        let command = DeriveWalletPublicKeysTask(walletPublicKey: walletPublicKey,
                                                 derivationPaths: derivationPaths)
        return command.eraseToAnyRunnable()
    }
}

class SetUserCodeRecoveryAllowedHandler: JSONRPCHandler {
    var method: String { "SET_USERCODE_RECOVERY_ALLOWED" }

    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let isAllowed: Bool = try parameters.value(for: "isAllowed")

        let command = SetUserCodeRecoveryAllowedTask(isAllowed: isAllowed)
        return command.eraseToAnyRunnable()
    }
}

class AttestCardKeyHandler: JSONRPCHandler {
    var method: String { "ATTEST_CARD_KEY" }

    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let attestationMode: AttestCardKeyCommand.Mode? = try parameters.value(for: "attestationMode")
        let challenge: Data? = try parameters.value(for: "challenge")

        let command: AttestCardKeyCommand

        if let attestationMode {
            command = AttestCardKeyCommand(mode: attestationMode, challenge: challenge)
        } else {
            command = AttestCardKeyCommand(challenge: challenge)
        }

        return command.eraseToAnyRunnable()
    }
}
