//
//  SessionViewDelegate.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

/// Allows interaction with users and shows visual elements.
/// Its default implementation, `DefaultSessionViewDelegate`, is in our SDK.
public protocol SessionViewDelegate: AnyObject {
    func showAlertMessage(_ text: String)
    
    /// It is called when tag was found
    func tagConnected()
    
    /// It is called when tag was lost
    func tagLost(message: String)
    
    func wrongCard(message: String)
    
    func sessionStarted()
    
    func sessionStopped(completion: (() -> Void)?)
    
    func attestationDidFail(isDevelopmentCard: Bool, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void)
    
    func attestationCompletedWithWarnings(onContinue: @escaping () -> Void)
    
    func attestationCompletedOffline(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void)
    
    func setState(_ state: SessionViewState)
}

/// Current state of the sdk's UI
public enum SessionViewState {
    case delay(remaining: Float, total: Float) //seconds
    case progress(percent: Int)
    case `default`
    case empty
    case scan
    case requestCode(_ type: UserCodeType, cardId: String?, showForgotButton: Bool, completion: CompletionResult<String>)
    case requestCodeChange(_ type: UserCodeType, cardId: String?, completion: CompletionResult<String>)

    var shouldPlayHaptics: Bool {
        switch self {
        case .delay, .progress:
            return true
        default:
            return false
        }
    }
}

extension UIAlertController {
    static func showShouldContinue(from controller: UIViewController, title: String, message: String, tint: UIColor, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common_understand".localized, style: .destructive) { _ in onContinue() })
        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel) { _ in onCancel() } )
        alert.view.tintColor = tint
        controller.present(alert, animated: true)
    }
    
    static func showShouldContinue(from controller: UIViewController, title: String, message: String, tint: UIColor, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common_understand".localized, style: .destructive) { _ in onContinue() })
        alert.addAction(UIAlertAction(title: "common_retry".localized, style: .default) { _ in onRetry() })
        alert.addAction(UIAlertAction(title: "common_cancel".localized, style: .cancel) { _ in onCancel() } )
        alert.view.tintColor = tint
        controller.present(alert, animated: true)
    }
    
    static func showAlert(from controller: UIViewController, title: String, message: String, tint: UIColor, onContinue: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common_ok".localized, style: .default) { _ in onContinue() })
        alert.view.tintColor = tint
        controller.present(alert, animated: true)
    }
}
