//
//  BiometricsUtil.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 01.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication

public final class BiometricsUtil {
    public static var isAvailable: Bool {
        var error: NSError?
        
        let context = LAContext.default
        let result = context.canEvaluatePolicy(authenticationPolicy, error: &error)
        
        if let error = error {
            Log.error(error)
        }
        
        return result
    }
    
    private static let authenticationPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    
    /// Request access to biometrics
    /// - Parameters:
    ///   - localizedReason:The app-provided reason for requesting authentication, which displays in the authentication dialog presented to the user. Must be non-empty. Only for touchID.
    ///   - completion: Result<Void, TangemSdkError>
    public static func requestAccess(localizedReason: String, completion: @escaping CompletionResult<LAContext>) {
        let context = LAContext.default
        
        DispatchQueue.global().async {
            context.evaluatePolicy(authenticationPolicy, localizedReason: localizedReason) { isSuccess, error in
                DispatchQueue.main.async {
                    guard let error = error else {
                        completion(.success(context))
                        return
                    }
                    
                    guard let laError = error as? LAError else {
                        completion(.failure(error.toTangemSdkError()))
                        return
                    }
                    
                    switch laError.code {
                    case .userCancel, .appCancel, .systemCancel:
                        completion(.failure(.userCancelled))
                    default:
                        completion(.failure(error.toTangemSdkError()))
                    }
                }
            }
        }
    }
}

