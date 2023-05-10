//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation
// Transactions
public protocol SuiTransactionStruct{
    func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws
    func inner() -> SuiTransactionInner
}
extension SuiTransactionStruct{
    public static func defaultType(dic: [String: AnyObject]) throws -> SuiTransactionArgumentType{
        guard let kind = dic["kind"] as? String else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid ArgumentType")
        }
        switch kind{
        case SuiGasCoinArgumentType.kind:
            return .GasCoin(SuiGasCoinArgumentType())
        case SuiResultArgumentType.kind:
            guard let index = dic["index"] as? UInt else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid ArgumentType")
            }
            return .Result(SuiResultArgumentType(index: UInt16(exactly: index)!))
        case SuiNestedResultArgumentType.kind:
            guard let index = dic["index"] as? UInt,
                  let resultIndex = dic["resultIndex"] as? UInt else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid ArgumentType")
            }
            return .NestedResult(SuiNestedResultArgumentType(index: UInt16(index), resultIndex: UInt16(resultIndex)))
        default:
            guard let index = dic["index"] as? UInt,
                  let type = dic["type"] as? String else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid ArgumentType")
            }
            if type == "object"{
                guard let objectid = dic["value"] as? String else{
                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid Object")
                }
                return .TransactionBlockInput(SuiTransactionBlockInput(index: UInt16(index), value: .Str(objectid), type: type))
            }
            if type == "pure"{
                if let value = dic["value"] as? String {
                    return .TransactionBlockInput(SuiTransactionBlockInput(index: UInt16(index), value: .Str(value), type: type))
                }
                if let value = dic["value"] as? [UInt8] {
                    return .TransactionBlockInput(SuiTransactionBlockInput(index: UInt16(index), value: .CallArg(.Pure(value)), type: type))
                }
                if let value = dic["value"]?["Pure"] as? [UInt8] {
                    return .TransactionBlockInput(SuiTransactionBlockInput(index: UInt16(index), value: .CallArg(.Pure(value)), type: type))
                }
            }
        }
        throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid ArgumentType")
    }
}
