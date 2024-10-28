//
//  PinCode.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

///// Contains information about the user code
struct UserCode {
    let type: UserCodeType
    let value: Data?
    
    init(_ type: UserCodeType) {
        self.value = type.defaultValue.sha256()
        self.type = type
    }
    
    init(_ type: UserCodeType, stringValue: String) {
        self.value = stringValue.sha256()
        self.type = type
    }
    
    init(_ type: UserCodeType, value: Data?) {
        self.value = value
        self.type = type
    }
}

public enum UserCodeType {
    case accessCode
    case passcode
    
    var defaultValue: String {
        switch self {
        case .accessCode:
            return UserCodeType.defaultAccessCode
        case .passcode:
            return UserCodeType.defaultPasscode
        }
    }
}

//MARK: Constants
extension UserCodeType {
    static let minLength = 4
    
    private static let defaultAccessCode = "000000"
    private static let defaultPasscode = "000"
}

extension UserCodeType {
    var name: String {
        switch self {
        case .accessCode:
            return "pin1".localized
        case .passcode:
            return "pin2".localized
        }
    }
    
    var enterCodeTitle: String {
        "pin_enter".localized(name.lowercasingFirst())
    }
    
    var enterNewCodeTitle: String {
        "pin_change_new_code_format".localized(name.lowercasingFirst())
    }
    
    var changeCodeTitle: String {
        "pin_set_code_format".localized(name.lowercasingFirst())
    }
    
    var confirmCodeTitle: String {
        "pin_set_code_confirm_format".localized(name.lowercasingFirst())
    }
    
    var resetCodeTitle: String {
        "pin_reset_code_format".localized(name.lowercasingFirst())
    }
    
    var shortLengthErrorMessage: String {
        switch self {
        case .accessCode:
            return TangemSdkError.accessCodeTooShort.localizedDescription
        case .passcode:
            return TangemSdkError.passcodeTooShort.localizedDescription
        }
    }
}
