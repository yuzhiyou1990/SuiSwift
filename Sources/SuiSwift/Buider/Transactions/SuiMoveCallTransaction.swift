//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation
import BigInt
public struct SuiMoveCallTransaction: SuiTransactionStruct{
    public static let kind: String = "MoveCall"
    public var target: String = ""
    public var typeArguments: [String]?
    public var arguments: [SuiTransactionArgumentType]
    public init(target: String, typeArguments: [String]? = nil, arguments: [SuiTransactionArgumentType]) {
        self.target = target
        self.typeArguments = typeArguments
        self.arguments = arguments
    }
    public init(target: String, typeArguments: [String]? = nil, arguments: [[String: Any]]) throws{
        self.target = target
        self.typeArguments = typeArguments
        self.arguments = try arguments.map { dic in
            return try SuiMoveCallTransaction.type(dic: dic)
        }
    }
    public static func type(dic: [String: Any]) throws -> SuiTransactionArgumentType{
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
            return .NestedResult(SuiNestedResultArgumentType(index: UInt16(exactly: index)!, resultIndex: UInt16(exactly: resultIndex)!))
        default:
            return .TransactionBlockInput(try SuiMoveCallTransaction.input(dic: dic))
        }
    }
    public static func input(dic: [String: Any]) throws -> SuiTransactionBlockInput{
        guard let index = dic["index"] as? UInt else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SuiTransactionBlockInput ArgumentType")
        }
        if let type = dic["type"] as? String {
            if type == "object"{
                guard let value = dic["value"] as? AnyObject else{
                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SuiTransactionBlockInput Object")
                }
                let jsonValue = try getObjectValue(argument: value)
                return SuiTransactionBlockInput(index: UInt16(index), value: jsonValue, type: type)
            }
            if type == "pure" {
                guard let value = dic["value"] as? AnyObject else{
                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SuiTransactionBlockInput")
                }
                let jsonValue = try getJsonValue(argument: value)
                return SuiTransactionBlockInput(index: UInt16(index), value: jsonValue, type: type)
            }
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SuiTransactionBlockInput")
        } else {
            return SuiTransactionBlockInput(index: UInt16(index))
        }
       
    }
    
    public static func getObjectValue(argument: AnyObject) throws -> SuiJsonValue{
        if let value = argument as? String {
            return .Str(value)
        } else if let value = argument as? [String: AnyObject], let object = value["Object"] as? [String: AnyObject] {
            if let shared = object["Shared"] as? [String: AnyObject],
               let objectId = shared["objectId"] as? String,
               let initialSharedVersion = shared["initialSharedVersion"] as? String,
               let number = UInt64(initialSharedVersion),
               let mutable = shared["mutable"] as? Bool {
                return .CallArg(.Object(.Shared(SuiSharedObjectRef(objectId: objectId, initialSharedVersion: number, mutable: mutable))))
            }
            if let ImmOrOwned = object["ImmOrOwned"] as? [String: AnyObject],
               let objectId = ImmOrOwned["objectId"] as? String,
               let version = ImmOrOwned["version"] as? String,
               let number = UInt64(version),
               let digest = ImmOrOwned["digest"] as? String {
                return .CallArg(.Object(.ImmOrOwned(SuiObjectRef(digest: digest, objectId: objectId, version: number))))
            }
        }
        throw SuiError.BuildTransactionError.ConstructTransactionDataError("Parse JsonValue Error")
    }
    
    public static func getJsonValue(argument: AnyObject) throws -> SuiJsonValue{
        if let value = argument as? String {
            return .Str(value)
        } else if let value = argument as? Bool{
            return .Boolean(value)
        } else if "\(argument)".isNumeric(){
            return .Number("\(argument)")
        } else if let value = argument as? [AnyObject]{
            let values = try value.map { obj in
                try getJsonValue(argument: obj)
            }
            return .Array(values)
        } else if let value = argument["Pure"] as? [UInt8]{
            return SuiJsonValue.CallArg(.Pure(value))
        }
        throw SuiError.BuildTransactionError.ConstructTransactionDataError("Parse JsonValue Error")
    }
    public func inner() -> SuiTransactionInner {
        return .MoveCall(self)
    }
}
extension String{
    func isNumeric() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[0-9]+$")
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
