//
//  ChangeUserCodeView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 13.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ChangeUserCodeView: View {
    let type: UserCodeType
    let title: String
    let cardId: String
    let placeholder: String
    let confirmationPlaceholder: String
    let completion: CompletionResult<String>
    
    @State private var code: String = ""
    @State private var confirmation: String = ""
    @State private var error: String = ""
    @State private var isContinueDisabled: Bool = true
    @State private var validationTimer: Timer? = nil
    
    @EnvironmentObject var style: TangemSdkStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            UserCodeHeaderView(title: title,
                               cardId: cardId,
                               onCancel: onCancel)
                .padding(.top, 8)
            
            FloatingTextField(title: placeholder,
                              text: $code.onUpdate(scheduleValidation),
                              onCommit: onDone,
                              shouldBecomeFirstResponder: true)
                .padding(.top, 16)
            
            FloatingTextField(title: confirmationPlaceholder,
                              text: $confirmation.onUpdate(scheduleValidation),
                              onCommit: onDone)
                .padding(.top, 8)
            
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(style.colors.errorTint)
            
            VStack(spacing: 0) {
                
                Spacer()
                
                Button("common_continue".localized, action: onDone)
                    .buttonStyle(RoundedButton(colors: style.colors.buttonColors,
                                               isDisabled: isContinueDisabled,
                                               isLoading: false))
            }
        }
        .padding([.horizontal, .bottom])
    }
    
    private func onCancel() {
        completion(.failure(.userCancelled))
    }
    
    private func onDone() {
        if !isContinueDisabled {
            UIApplication.shared.endEditing()
            completion(.success(code.trim()))
        }
    }
    
    private func scheduleValidation() {
        validationTimer?.invalidate()
        validationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: validateInput)
    }
    
    private func validateInput(_ timer: Timer? = nil) {
        let trimmedCode = code.trim()
        let trimmedConfirmation = confirmation.trim()
        
        guard !trimmedCode.isEmpty, !trimmedConfirmation.isEmpty else {
            error = ""
            isContinueDisabled = true
            return
        }
        
        if code != confirmation {
            error = "pin_confirm_error_format".localized
            isContinueDisabled = true
            return
        }
        
        if trimmedCode.count < UserCodeType.minLength {
            error = type.shortLengthErrorMessage
            isContinueDisabled = true
            return
        }
        
        error = ""
        isContinueDisabled = false
        return
    }
}

struct ChangeUserCodeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChangeUserCodeView(type: .accessCode,
                               title: "Title",
                               cardId: "0000 1111 2222 3333 444",
                               placeholder: "Enter code",
                               confirmationPlaceholder: "Confirm",
                               completion: {_ in})
            ChangeUserCodeView(type: .accessCode,
                               title: "Title",
                               cardId: "0000 1111 2222 3333 444",
                               placeholder: "Enter code",
                               confirmationPlaceholder: "Confirm",
                               completion: {_ in})
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
