//
//  File.swift
//  
//
//  Created by li shuai on 2022/10/26.
//

import Foundation
public class SuiError{
    public enum BCSError: LocalizedError{
        case SerializeError(String? = nil)
        case DeserializeError(String? = nil)
        public var errorDescription: String?{
            switch self{
            case .SerializeError(let string):
                return "BCS Serialize Error: \(string ?? "UNKNOW")"
            case .DeserializeError(let string):
                return "BCS Deserialize Error: \(string ?? "UNKNOW")"
            }
        }
    }
    public enum KeypairError: LocalizedError{
        case NotExpected
        case SignError
        case InvalidSignatureScheme
        case InvalidSeed
        case InvalidSecretKey
        case InvalidMnemonics
        case InvalidPublicKey
        case InvalidAddress
        case otherEror(String)
        public var errorDescription: String?{
            switch self {
            case .NotExpected:
                return "Not Expected"
            case .SignError:
                return "Sign Error"
            case .InvalidSignatureScheme:
                return "Invalid signType"
            case .InvalidSeed:
                return "Invalid Seed"
            case .InvalidSecretKey:
                return "Invalid SecretKey"
            case .InvalidMnemonics:
                return "Invalid Mnemonics"
            case .InvalidPublicKey:
                return "Invalid PublicKey"
            case .InvalidAddress:
                return "Invalid Address"
            case .otherEror(let string):
                return string
            }
        }
    }
    public enum RPCError: LocalizedError {
        case EncodingError
        case DecodingError(_ message: String, _ data: String? = "")
        case ApiResponseError(method: String, message: String)
        public var errorDescription: String? {
            switch self {
            case .EncodingError:
                return "Encoding Error"
            case .DecodingError(let message, let data):
                return "Decode Error: \(message); Response Data: \(data ?? "")"
            case .ApiResponseError(method: let method, message: let message):
                return "Response Error method:\(method), Message:\(message)"
            }
        }
    }
    
    public enum TransactionResponseError: LocalizedError{
        case DecodingError(modelName: String, message: String? = nil)
        public var errorDescription: String? {
            switch self {
            case .DecodingError(let modelName, let message):
                return "Decoding  Error ModelName: \(modelName); Message: \(message ?? "")"
            }
        }
    }
    public enum BuildTransactionError: LocalizedError{
        case InvalidSignData
        case InvalidSerializeData
        case ConstructTransactionDataError(_ message: String? = nil)
        public var errorDescription: String? {
            switch self {
            case .ConstructTransactionDataError(let message):
                return "BuildTransactionError Message: \(message ?? "")"
            case .InvalidSignData:
                return "Invalid SignData"
            case .InvalidSerializeData:
                return "Invalid SerializeData"
            }
        }
    }
    public enum DataSerializerError: LocalizedError{
        case ParseError(String?)
        public var errorDescription: String? {
            switch self {
            case .ParseError(let message):
                return "Parse Error: \(message ?? "UNKNOW")"
            }
        }
    }
}
