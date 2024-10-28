//
//  ViewModel.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class ViewModel<ViewState>: ObservableObject {
    @Published var viewState: ViewState
    
    init(viewState: ViewState) {
        self.viewState = viewState
    }
}
