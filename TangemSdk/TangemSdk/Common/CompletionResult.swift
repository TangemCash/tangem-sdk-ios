//
//  CompletionResult.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public typealias CompletionResult<T> = (Result<T, TangemSdkError>) -> Void
