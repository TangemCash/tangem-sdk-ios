//
//  UserCodeHeaderView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 13.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserCodeHeaderView: View {
    let title: String
    let cardId: String
    let onCancel: (() -> Void)
    
    @EnvironmentObject var style: TangemSdkStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Button("common_cancel".localized, action: onCancel)
                    .foregroundColor(style.colors.tint)
            }.padding(.bottom, 16)
            
            Text(title)
                .font(Font.system(size: 24).bold())
                .lineLimit(1)
            
            Text(cardId)
                .font(.system(size: 17))
        }
    }
}

struct UserCodeHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserCodeHeaderView(title: "Enter access code", cardId: "0000 0000 0000 0000", onCancel: {})
            UserCodeHeaderView(title: "Enter access code", cardId: "0000 0000 0000 0000", onCancel: {})
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
