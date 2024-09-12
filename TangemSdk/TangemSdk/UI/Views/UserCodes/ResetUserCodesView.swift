//
//  ResetUserCodesView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ResetUserCodesView: View {
    let title: String
    let cardId: String
    let card: CardType
    let messageTitle: String
    let messageBody: String
    let completion: CompletionResult<Bool>
    
    @EnvironmentObject var style: TangemSdkStyle
    
    @State private var isLoading: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 0) {
                UserCodeHeaderView(title: title,
                                   cardId: cardId,
                                   onCancel: onCancel)
                    .padding(.top, 8)
                    .padding(.bottom, 50)
                
                cardsStack(geo.size)
                
                Spacer()
                
                Text(messageTitle)
                    .font(Font.system(size: 28).bold())
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
                
                Text(messageBody)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
                
                Spacer()
                
                Button("common_continue".localized, action: onContinue)
                    .buttonStyle(RoundedButton(colors: style.colors.buttonColors,
                                               isLoading: isLoading))
                
            }
        }
        .padding([.horizontal, .bottom])
        .onAppear {
            if isLoading {
                isLoading = false
            }
        }
    }
    
    @ViewBuilder
    private func cardsStack(_ size: CGSize) -> some View {
        let topCardWidth = 0.8 * size.width
        let topCardHeight = 0.6 * topCardWidth
        
        let bottomCardWidth = 0.88 * topCardWidth
        let bottomCardHeight = 0.88 * topCardHeight
        
        let cards: [BadgedCardView] = [ .init(cardColor: Color(UIColor.systemGray5),
                                              starsColor: .gray,
                                              name: "reset_codes_linked_card".localized,
                                              badgeBackground: .gray.opacity(0.25),
                                              badgeForeground: .gray),
                                        
                                        .init(cardColor: style.colors.tint,
                                              starsColor: .white,
                                              name: "reset_codes_current_card".localized,
                                              badgeBackground: .white.opacity(0.25),
                                              badgeForeground: .white)]
        ZStack {
            cards[card.topIndex]
                .frame(width: bottomCardWidth, height: bottomCardHeight)
                .offset(y: 0.16 * bottomCardHeight)
            
            cards[card.bottomIndex]
                .frame(width: topCardWidth, height: topCardHeight)
        }
    }
    
    private func onCancel() {
        completion(.failure(.userCancelled))
    }
    
    private func onContinue() {
        completion(.success(true))
    }
}

struct ResetUserCodesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResetUserCodesView(title: "Reset access code",
                               cardId: "Card 0000 1111 2222 3333 444",
                               card: .origin,
                               messageTitle: "Tap the card you want to restore",
                               messageBody: "First, prepare the card for restore process.",
                               completion: { _ in })
            
            ResetUserCodesView(title: "Reset access code",
                               cardId: "Card 0000 1111 2222 3333 444",
                               card: .backup,
                               messageTitle: "Tap the card you want to restore",
                               messageBody: "First, prepare the card for restore process.",
                               completion: { _ in })
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
