//
//  Publisher+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 13.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

extension Publisher where Failure == Never {
    func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on root: Root) -> AnyCancellable {
       sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
