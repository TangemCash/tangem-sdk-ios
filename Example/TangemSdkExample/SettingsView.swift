//
//  SettingsView.swift
//  TangemSdkExample
//
//  Created by Alexander Osokin on 21.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        VStack {
            Toggle("Error handling", isOn: $model.handleErrors)
            
            Toggle("Display logs", isOn: $model.displayLogs)
            
            Text("User code request policy")
                .fontWeight(.bold)
                .padding()
            
            Picker("", selection: $model.userCodeRequestPolicy) {
                ForEach(0..<UserCodeRequestPolicy.allCases.count, id: \.self) { index in
                    Text(UserCodeRequestPolicy.allCases[index].rawValue)
                        .tag(UserCodeRequestPolicy.allCases[index])
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Button("Remove user codes", action: model.onRemoveUserCodes)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("Settings", displayMode: .inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppModel())
    }
}
