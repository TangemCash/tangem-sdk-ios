//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias ReadResponse = Card

/// This command receives from the Tangem Card all the data about the card and the wallet,
///  including unique card number (CID or cardId) that has to be submitted while calling all other commands.
@available(iOS 13.0, *)
public final class ReadCommand: Command {
    public typealias CommandResponse = ReadResponse
    
    public var needPreflightRead: Bool {
        return false
    }
	
	private var walletIndex: WalletIndex?
	
	public init(walletIndex: WalletIndex? = nil) {
		self.walletIndex = walletIndex
	}
	
    deinit {
        print("ReadCommand deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadResponse>) {
        transieve(in: session) { result in
            switch result {
            case .success(let readResponse):
                session.environment.card = readResponse
                completion(.success(readResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            return .pin1Required
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        /// `SessionEnvironment` stores the pin1 value. If no pin1 value was set, it will contain
        /// default value of ‘000000’.
        /// In order to obtain card’s data, [ReadCommand] should use the correct pin 1 value.
        /// The card will not respond if wrong pin 1 has been submitted.
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1.value)
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
		try walletIndex?.addTlvData(to: tlvBuilder)
		
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadResponse {
		let readResponse = try CardDeserializer.deserialize(with: environment, from: apdu)
        
		if readResponse.firmwareVersion >= FirmwareConstraints.AvailabilityVersions.walletData,
		   let index = walletIndex {
			
			switch index {
			case .index(let i):
				if readResponse.walletIndex != i {
					throw TangemSdkError.cardReadWrongWallet
				}
			case .publicKey(let pubKey):
				if let publicKeyOnCard = readResponse.walletPublicKey, publicKeyOnCard != pubKey {
					throw TangemSdkError.cardReadWrongWallet
				}
			}
			
		}
		
		return readResponse
    }
}
