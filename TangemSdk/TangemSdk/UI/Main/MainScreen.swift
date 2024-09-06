//
//  MainScreen.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainScreen: View {
    @EnvironmentObject var viewModel: MainViewModel
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
        case .scan:
            ReadView()
            
        case .requestCode(let type, cardId: let cardId, let showForgotButton, completion: let completion):
            EnterUserCodeView(title: type.enterCodeTitle,
                              cardId: cardId ?? "",
                              placeholder: type.name,
                              showForgotButton: showForgotButton,
                              completion: completion)
            
        case .requestCodeChange(let type, cardId: let cardId, completion: let completion):
            ChangeUserCodeView(type: type,
                               title: type.changeCodeTitle,
                               cardId: cardId ?? "",
                               placeholder: type.enterNewCodeTitle,
                               confirmationPlaceholder: type.confirmCodeTitle,
                               completion: completion)
        case .empty:
            EmptyView()
        default:
            indicatorView(self.viewModel.viewState.indicatorState!)
        }
    }
    
    @ViewBuilder
    private func indicatorView(_ state: IndicatorView.ViewState) -> some View {
        GeometryReader { geo in
            
            let sheetHeight =  UIScreen.main.isZoomedMode && UIScreen.main.scale < 3 ? Constants.nfcSheetHeightZoomed : Constants.nfcSheetHeight
            let availableSpace = min(geo.size.width, geo.size.height - sheetHeight, Constants.indicatorMaxSize)
            let indicatorSize = availableSpace * 0.8

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    IndicatorView(state: state)
                        .frame(width: indicatorSize, height: indicatorSize)
                    Spacer()
                }
                Spacer()
            }
            .padding(.bottom, sheetHeight)
        }
    }
}

private extension MainScreen {
    enum Constants {
        static let indicatorMaxSize: CGFloat = 280
        static let nfcSheetHeightZoomed: CGFloat = 310 //iPhone 7
        static let nfcSheetHeight: CGFloat = 390
    }
}

struct MainScreen_Preview: PreviewProvider {
    static var previews: some View {
        MainScreen()
            .environmentObject(MainViewModel(viewState: .scan))
            .environmentObject(TangemSdkStyle())
    }
}

fileprivate extension SessionViewState {
    var indicatorState: IndicatorView.ViewState? {
        switch self {
        case .default:
            return .spinner
            
        case .delay(let remaining, let total):
            return .delay(currentValue: CGFloat(remaining),
                          totalValue: CGFloat(total))
            
        case .progress(let progress):
            return.progress(progress: progress)
        default:
            return nil
        }
    }
}
