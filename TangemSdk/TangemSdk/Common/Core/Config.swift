//
//  Config.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Config {    
    public init() {}
    /**
     This feature forces low-level NFC communication between the Tangem card and the particular device. If it’s set to true, Tangem Card will send low-level packets to the device’s NFC chip every about 50ms. It will prevent some chip’s firmware bugs on iPhone 7/7+, when iOS is stoping NFC session due to losing the tag. Also, it will make NFC interaction slower. Change this setting only if you understand what you do.
    
     If nil, TangemSdk will turn on this feature automatically according to iPhone model
    
     Tangem card supports this setting from firmware v.2.39. Otherwise, it would be ignored.
     */
    public var legacyMode: Bool? = nil
    
    /**
     Enables or disables Linked Terminal feature. Default is **true**
     # Notes: #
     App can optionally generate ECDSA key pair Terminal_PrivateKey / Terminal_PublicKey. And then submit Terminal_PublicKey to the card in any SIGN command. Once SIGN is successfully executed by COS (Card Operation System), including PIN2 verification and/or completion of security delay, the submitted Terminal_PublicKey key is stored by COS. After that, the App instance is deemed trusted by COS and COS will allow skipping security delay for subsequent SIGN operations thus improving convenience without sacrificing security.
     
     In order to skip security delay, App should use Terminal_PrivateKey to compute the signature of the data being submitted to SIGN command for signing and transmit this signature in Terminal_Transaction_Signature parameter in the same SIGN command. COS will verify the correctness of Terminal_Transaction_Signature using previously stored Terminal_PublicKey and, if correct, will skip security delay for the current SIGN operation.
     
     If nil, TangemSdk will turn on this feature automatically according to iPhone model
     
     COS version 2.30 and later.
     */
    public var linkedTerminal: Bool? = nil
    
    /// If not nil, will be used to validate Issuer data and issuer extra data. If nil, issuerPublicKey from current card will be used
    public var issuerPublicKey: Data?
    
    public var handleErrors: Bool = true

    /// Card id display format. Full card id will be displayed by default
    public var cardIdDisplayFormat: CardIdDisplayFormat = .full

    /// Product to work with. Affect animations and texts.
    public var productType: ProductType = .any

    /// Logger configuration
    public var logConfig: Log.Config = .default
    
    /// ScanTask or scanCard method in TangemSdk class will use this mode to attest the card
    public var attestationMode: AttestationTask.Mode = .normal
    
    /// If true, BAP cards will pass online attestation. Use only for debugging purposes and if you understand what to do
    public var allowUntrustedCards: Bool = false
    
    public var filter: CardFilter = .default
    
    public var style: TangemSdkStyle = .default
    
    /// Convert all secp256k1 signatures, produced by the card, to a lower-S form. True by default
    public var canonizeSecp256k1Signatures: Bool = true
    
    /// A card with HD wallets feature enabled will derive keys automatically on "scan" and "createWallet". Repeated items will be ignored
    /// All derived keys will be stored in `Card.Wallet.derivedKeys`.
    /// Only `secp256k1` and `ed25519` supported
    public var defaultDerivationPaths: [EllipticCurve: [DerivationPath]] = [:]
    
    /// Access codes  request policy
    public var accessCodeRequestPolicy: AccessCodeRequestPolicy = .`default`
    
    /// Localized reason for Touch ID. DO NOT leave it empty.
    public var biometricsLocalizedReason: String = "touch_id_localized_reason".localized

    public mutating func setupForProduct(_ product: ProductType) {
        switch product {
        case .card:
            productType = .card
            cardIdDisplayFormat = .full
            style.scanTagImage = .genericCard
        case .ring:
            productType = .ring
            cardIdDisplayFormat = .none
            style.scanTagImage = .genericRing
        case .any:
            productType = .any
            cardIdDisplayFormat = .full
            style.scanTagImage = .genericCard
        }
    }
}

public enum CardIdDisplayFormat {
    /// Don't show the cardId
    case none
    /// Full cardId splitted by 4 numbers
    case full
    /// n numbers from the end
    case last(_ numbers: Int)
    /// n numbers from the end with mask, e.g.  * * *1234
    case lastMasked(_ numbers: Int, mask: String = "***")
    /// n numbers from the end except last
    case lastLunh(_ numbers: Int)
}

public enum AccessCodeRequestPolicy: String, CaseIterable {
    /// User code will be requested before card scan. Biometrics will be used if enabled and there are any saved codes.
    case alwaysWithBiometrics
    /// User code will be requested before card scan.
    case always
    /// User code will be requested only if set on the card. Need scan the card twice.
    case `default`
}

public enum ProductType {
    case any
    case card
    case ring

    @available(iOS 13.0, *)
    var localizedDescription: String {
        switch self {
        case .card:
            "common_card".localized
        case .ring:
            "common_ring".localized
        case .any:
            "common_card_or_ring".localized
        }
    }
}
