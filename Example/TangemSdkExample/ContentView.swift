//
//  ContentView.swift
//  TangemSDKExample
//
//  Created by Alexander Osokin on 04.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    destination: model.makeBackupDestination(),
                    isActive: $model.showBackupView,
                    label: {EmptyView()})
                
                NavigationLink(
                    destination: model.makeSettingsDestination(),
                    isActive: $model.showSettings,
                    label: {EmptyView()})
                
                NavigationLink(
                    destination: model.makePinResetDestination(),
                    isActive: $model.showResetPin,
                    label: {EmptyView()})
                
                GeometryReader { geo in
                    VStack {
                        ScrollView {
                            HStack {
                                Text(model.logText)
                                    .font(.caption)
                                
                                Spacer()
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 14)
                        .clipped()
                        .frame(width: geo.size.width)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange, lineWidth: 2)
                                    .padding(.horizontal, 8))
                        .layoutPriority(-1)
                        
                        VStack(spacing: 4) {
                            HStack {
                                Button("Clear", action: model.clear)
                                Button("Copy", action: model.copy)
                                Button("Backup", action: model.onBackup)
                                Button("Reset", action: model.onResetService)
                                Button("Hide kb", action: model.hideKeyboard)
                            }
                            
                            additionalView
                                .padding(.top, 4)
                            
                            Picker("", selection: $model.method) {
                                ForEach(0..<AppModel.Method.allCases.count, id: \.self) { index in
                                    Text(AppModel.Method.allCases[index].rawValue)
                                        .tag(AppModel.Method.allCases[index])
                                }
                            }
                            .frame(minHeight: 110)
                            .labelsHidden()
                            .pickerStyle(WheelPickerStyle())
                            
                            Button("Start") { model.start() }
                                .buttonStyle(ExampleButton(isLoading: model.isScanning))
                                .frame(width: 100)
                            
                        }
                        .padding(.horizontal, 8)
                        .frame(width: geo.size.width)
                    }
                }
            }
            .navigationBarTitle("SDK", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: model.onSettings,
                                                 label: { Image(systemName: "gear")}))
        }
        .padding(.bottom, 8)
        .actionSheet(isPresented: $model.showWalletSelection) {
            let walletButtons: [Alert.Button] = model.card?.wallets.map { wallet in
                let publicKey = wallet.publicKey.hexString
                let formattedKey = "\(publicKey.prefix(6))...\(publicKey.suffix(6)) (\(wallet.curve.rawValue))"
                
                return ActionSheet.Button.default(Text(formattedKey)) {
                    model.start(walletPublicKey: wallet.publicKey)
                }
            } ?? []
            
            let cancelButton = ActionSheet.Button.cancel {
                model.isScanning = false
            }
            
            return ActionSheet(title: Text("Select wallet"),
                               message: nil,
                               buttons: walletButtons + [cancelButton])
        }
    }
    
    @ViewBuilder
    private var additionalView: some View {
        switch model.method {
        case .attest:
            VStack {
                Text("Attestation configuration")
                    .font(.headline)
                    .bold()
                
                Picker("", selection: $model.attestationMode) {
                    ForEach(0..<AttestationTask.Mode.allCases.count, id: \.self) { index in
                        Text(AttestationTask.Mode.allCases[index].rawValue)
                            .tag(AttestationTask.Mode.allCases[index])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        case .createWallet, .importWallet:
            VStack {
                Text("Create wallet configuration")
                    .font(.headline)
                    .bold()
                
                if let supportedCurves = model.card?.supportedCurves {
                    Picker("", selection: $model.curve) {
                        ForEach(0..<supportedCurves.count, id: \.self) { index in
                            Text(supportedCurves[index].rawValue)
                                .tag(supportedCurves[index])
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }

                if case .importWallet = model.method {
                    TextField("Optional mnemonic", text: $model.mnemonicString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)

                    TextField("Optional passphrase", text: $model.passphrase)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                }
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        case .signHash, .signHashes, .derivePublicKey:
            VStack {
                Text("Hd path")
                    .font(.headline)
                    .bold()
                
                TextField("\"m/0/1\"", text: $model.derivationPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if case .signHashes = model.method {
                    Text("Sign hashes count")
                        .font(.headline)
                        .bold()

                    TextField("", text: $model.signHashesCount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                }
            }
            .padding()
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
        case .jsonrpc, .personalize:
            VStack {
                Text("JSON editor")
                    .font(.headline)
                    .bold()
                
                TextEditor(text: $model.editorData)
                    .frame(height: 100)

                HStack {
                    Spacer()
                    Button("Paste json", action: model.pasteEditor)
                    Spacer()
                    Button("End editing", action: model.endEditing)
                    Spacer()
                }
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding(.vertical, 8)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2))
            .onAppear(perform: model.onAppear)
        case .setUserCodeRecoveryAllowed:
            Toggle(isOn: $model.isUserCodeRecoveryAllowed) {
                Text("Is user code recovery allowed")
            }
        default:
            EmptyView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var model = AppModel()
    
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 8")
            .environmentObject(model)
    }
}
