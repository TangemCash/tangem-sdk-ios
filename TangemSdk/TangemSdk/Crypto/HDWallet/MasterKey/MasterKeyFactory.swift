//
//  MasterKeyFactory.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MasterKeyFactory {
    func makePrivateKey() throws -> ExtendedPrivateKey
}
