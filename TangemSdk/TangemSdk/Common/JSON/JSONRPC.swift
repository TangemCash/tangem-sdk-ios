//
//  JSONRPCRequest.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 14.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public final class JSONRPCConverter {
    public static let shared: JSONRPCConverter = {
        let converter = JSONRPCConverter()
        converter.register(ScanHandler())
        converter.register(AttestCardKeyHandler())
        converter.register(SignHashHandler())
        converter.register(SignHashesHandler())
        converter.register(CreateWalletHandler())
        converter.register(ImportWalletHandler())
        converter.register(PurgeWalletHandler())
        converter.register(SetAccessCodeHandler())
        converter.register(SetPasscodeHandler())
        converter.register(ResetUserCodesHandler())
        converter.register(SetUserCodeRecoveryAllowedHandler())
        converter.register(DeriveWalletPublicKeyHandler())
        converter.register(DeriveWalletPublicKeysHandler())
        converter.register(ReadFilesHandler())
        converter.register(ChangeFileSettingsHandler())
        converter.register(WriteFilesHandler())
        converter.register(DeleteFilesHandler())
        converter.register(PersonalizeHandler())
        converter.register(DepersonalizeHandler())
        return converter
    }()
    
    public private(set) var handlers: [String: JSONRPCHandler] = [:]
    
    private init() {}
    
    deinit {
        Log.debug("JSONRPCConverter deinit")
    }
    
    public func register(_ object: JSONRPCHandler) {
        handlers[object.method.lowercased()] = object
    }
    
    public func convert(request: JSONRPCRequest) throws -> AnyJSONRPCRunnable {
        let handler = try getHandler(from: request)
        let runnable = try handler.makeRunnable(from: request.params)
        runnable.id = request.id
        return runnable
    }
    
    public func getHandler(from request: JSONRPCRequest) throws -> JSONRPCHandler {
        guard let handler = handlers[request.method.lowercased()] else {
            throw JSONRPCError(.methodNotFound, data: JSONRPCErrorData(.methodNotFound, message: request.method))
        }
        
        return handler
    }
}

public protocol JSONRPCHandler {
    var method: String { get }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable
}


// MARK: - JSONRPC Specification
public struct JSONRPCRequest {
    public let jsonrpc: String
    public let id: Int?
    public let method: String
    public let params: [String: Any]
    
    public init(id: Int?, method: String, params: [String : Any]) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
    
    public init(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONRPCError(.parseError)
        }
        
        try self.init(data: data)
    }
    
    public init(data: Data) throws {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                try self.init(json: json)
            } else {
                throw JSONRPCError(.parseError)
            }
        } catch {
            throw JSONRPCError(.parseError, data: JSONRPCErrorData(.parseError, message: error.localizedDescription))
        }
    }
    
    public init(json: [String: Any]) throws {
        jsonrpc = json["jsonrpc"] as? String ?? "2.0" //todo make it mandatory
        id = json["id"] as? Int
        params = json["params"] as? [String:Any] ?? [:]
        
        if let methodValue = json["method"] as? String {
            method = methodValue
        } else {
            throw JSONRPCError(.invalidRequest, data: JSONRPCErrorData(.invalidRequest, message: "Failed to parse method"))
        }
    }
}

struct JSONRPCRequestParser {
    func parse(jsonString: String) throws -> ParseResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw JSONRPCError(.parseError)
        }
        
        if let requestArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
            let requests = try requestArray.map { try JSONRPCRequest(json: $0 )}
            if requests.isEmpty {
                throw JSONRPCError(.invalidRequest)
            }
            return .array(requests)
        } else {
            let request = try JSONRPCRequest(data: data)
            return .single(request)
        }
    }
    
    enum ParseResult {
        case array([JSONRPCRequest])
        case single(JSONRPCRequest)
        
        var requests: [JSONRPCRequest] {
            switch self {
            case .array(let requests):
                return requests
            case .single(let request):
                return [request]
            }
        }
    }
}

public struct JSONRPCResponse: JSONStringConvertible {
    public let jsonrpc: String
    public let result: AnyJSONRPCResponse?
    public let error: JSONRPCError?
    public let id: Int?
    
    public init(id: Int?, result: AnyJSONRPCResponse?, error: JSONRPCError?) {
        self.jsonrpc = "2.0"
        self.result = result
        self.error = error
        self.id = id
    }
}

extension Array: JSONStringConvertible where Element: JSONStringConvertible {}

public struct JSONRPCError: Error, JSONStringConvertible, Equatable {
    public let code: Int
    public let message: String
    public let data: JSONRPCErrorData?
    
    public init(code: Int, message: String, data: JSONRPCErrorData?) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    public init(_ code: JSONRPCError.Code, data: JSONRPCErrorData? = nil) {
        self.code = code.rawValue
        self.message = code.message
        self.data = data
    }
}

public struct JSONRPCErrorData: Encodable, Equatable, JSONStringConvertible {
    public let code: Int
    public let message: String
}

extension JSONRPCErrorData {
    public init(_ code: JSONRPCError.Code, message: String) {
        self.code = code.rawValue
        self.message = message
    }
}

extension JSONRPCError {
    public enum Code: Int {
        case parseError = -32700
        case invalidRequest = -32600
        case methodNotFound = -32601
        case invalidParams = -32602
        case internalError = -32603
        case serverError = -32000
        
        var message: String { //TODO: localize
            switch self {
            case .internalError:
                return "Internal error"
            case .invalidParams:
                return "Invalid parameters"
            case .invalidRequest:
                return "Invalid request"
            case .methodNotFound:
                return "Method not found"
            case .parseError:
                return "Parse error"
            case .serverError:
                return "Server error"
            }
        }
    }
}

// MARK: - JSONRPC Helper extensions
extension Result where Success: JSONStringConvertible, Failure == TangemSdkError {
    func toJsonResponse(id: Int? = nil) -> JSONRPCResponse {
        switch self {
        case .success(let response):
            return JSONRPCResponse(id: id, result: response.eraseToAnyResponse(), error: nil)
        case .failure(let error):
            return error.toJsonResponse(id: id)
        }
    }
}

extension Error {
    func toJsonResponse(id: Int? = nil) -> JSONRPCResponse {
        return JSONRPCResponse(id: id, result: nil, error: toJsonError())
    }
    
    func toJsonError() -> JSONRPCError {
        if let jsonError = self as? JSONRPCError {
            return jsonError
        } else {
            let sdkError = toTangemSdkError()
            let data = JSONRPCErrorData(code: sdkError.code, message: "\(sdkError)".capitalizingFirst())
            return JSONRPCError(.serverError, data: data)
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    func value<T: Decodable>(for key: String) throws -> T where T: ExpressibleByNilLiteral {
        let value = self[key]
        if value == nil || String(describing: value) == "Optional(<null>)" {
            return nil
        }
        
        return try decode(value!, for: key)
    }
    
    func value<T: Decodable>(for key: String) throws -> T {
        let value = self[key]
        if value == nil || String(describing: value) == "<null>" {
            throw JSONRPCError(.invalidParams, data: JSONRPCErrorData(.invalidParams, message: key))
        }
        
        return try decode(value!, for: key)
    }
    
    private func decode<T: Decodable>(_ value: Any, for key: String) throws -> T {
        if T.self == Data.self || T.self == Data?.self {
            if let hex = value as? String {
                return (Data(hexString: hex) as! T)
            } else {
                throw JSONRPCError(.parseError, data: JSONRPCErrorData(.parseError, message: key))
            }
        }
        
        if T.self == [Data].self || T.self == [Data]?.self {
            if let hex = value as? [String] {
                return hex.compactMap { Data(hexString: $0) } as! T
            } else {
                throw JSONRPCError(.parseError, data: JSONRPCErrorData(.parseError, message: key))
            }
        }
        
        if let converted = value as? T {
            return converted
        }
        
        var someError: Error? = nil
        
        do {
            if let jsonData =  "\"\(value)\"".data(using: .utf8) {
                return try JSONDecoder.tangemSdkDecoder.decode(T.self, from: jsonData)
            }
        } catch {
            someError = error
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
            return try JSONDecoder.tangemSdkDecoder.decode(T.self, from: jsonData)
        } catch {
            someError = error
        }
        
        throw someError ?? JSONRPCError(.parseError, data: JSONRPCErrorData(.parseError, message: key))
    }
}
