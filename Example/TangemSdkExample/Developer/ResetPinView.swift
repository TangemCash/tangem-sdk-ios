//
//  ResetPinView.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct ResetPinView: View {
    var resetPinService: ResetPinService
    
    private var stateTitle: String { "Current state is: \(resetPinService.currentState)" }
    @State private var accessCode: String = ""
    @State private var passcode: String = ""
    @State private var errorText: String = ""
    @State private var showOkAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            
            Text(stateTitle)
                .padding(.top, 40)
                .font(.title)
            
            
            TextField("Access code", text: $accessCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Set access code") {
                do {
                    try resetPinService.setAccessCode(accessCode)
                    self.errorText = ""
                    showOkAlert = true
                    UIApplication.shared.endEditing()
                } catch {
                    self.errorText = "Error occured: \(error)"
                }
            }
            .buttonStyle(ExampleButton(isLoading: false))
            .frame(width: 200)
            
            TextField("Passcode", text: $passcode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Set passcode") {
                do {
                    try resetPinService.setPasscode(passcode)
                    self.errorText = ""
                    showOkAlert = true
                    UIApplication.shared.endEditing()
                } catch {
                    self.errorText = "Error occured: \(error)"
                }
            }
            .buttonStyle(ExampleButton(isLoading: false))
            .frame(width: 200)
            
            Text(errorText)
                .foregroundColor(.red)
            
            if let error = resetPinService.error {
                Text("Error occured: \(error.localizedDescription)")
            }
            
            Spacer()
            
            Button("Proceed", action: { resetPinService.proceed() })
                .buttonStyle(ExampleButton(isLoading: false))
                .frame(width: 200)
        }
        .padding(.horizontal, 16)
        .navigationBarTitle("Reset user codes", displayMode: .inline)
        .alert(isPresented: $showOkAlert, content: {
            Alert(title: Text("Success"), message: Text("Code accepted"))
        })
    }
}

struct ResetPinView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPinView(resetPinService: ResetPinService(config: Config()))
    }
}
