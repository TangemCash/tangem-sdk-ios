//
//  ResetCodesScreen.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ResetCodesScreen: View {
    @EnvironmentObject var viewModel: ResetCodesViewModel
    @EnvironmentObject var style: TangemSdkStyle
    
    var body: some View {
        mainView
            .transition(AnyTransition
                            .identity
                            .combined(with: .opacity))
            .environmentObject(style)
    }
    
    @ViewBuilder
    private var mainView: some View {
        switch viewModel.viewState {
        case .requestCode(let type, cardId: let cardId, completion: let completion):
            ChangeUserCodeView(type: type,
                               title: type.enterNewCodeTitle,
                               cardId: cardId ?? "",
                               placeholder: type.name,
                               confirmationPlaceholder: type.confirmCodeTitle,
                               completion: completion)
            
        case .resetCodes(let type, let state, cardId: let cardId, completion: let completion):
            ResetUserCodesView(title: type.resetCodeTitle,
                               cardId: cardId ?? "",
                               card: state.cardType,
                               messageTitle: state.messageTitle,
                               messageBody: state.messageBody,
                               completion: completion)
        default:
            EmptyView()
        }
    }
}


struct ResetUserCodesScreen_Preview: PreviewProvider {
    static var previews: some View {
        ResetCodesScreen()
            .environmentObject(ResetCodesViewModel(viewState: .empty))
            .environmentObject(TangemSdkStyle())
    }
}
