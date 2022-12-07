//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

public typealias SuiJsonValue = SuiMoveCallTransaction.SuiJsonValue
public struct SuiMoveCallTransaction: SuiUnserializedSignableTransaction{
    public enum SuiJsonValue{
        case Boolean(Bool)
        case Number(UInt64)
        case Str(String)
        case Array([SuiJsonValue])
    }
    public enum TypeArguments{
        case Strings([String])
        case TypeTags([SuiTypeTag])
    }
    public var packageObjectId: SuiObjectId
    public var module: String
    public var function: String
    public var typeArguments: TypeArguments
    public var arguments: [SuiJsonValue]
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public init(packageObjectId: SuiObjectId, module: String, function: String, typeArguments: TypeArguments, arguments: [SuiJsonValue], gasPayment: SuiObjectId? = nil, gasBudget: UInt64) {
        self.packageObjectId = packageObjectId
        self.module = module
        self.function = function
        self.typeArguments = typeArguments
        self.arguments = arguments
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
    }
    public func bcsTransaction() -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                guard let packageObjectRef = try? SuiJsonRpcProvider.shared.getObjectRef(objectId: packageObjectId).wait() else{
                    throw SuiError.BCSError.SerializeError("Serialize SuiMoveCallTransaction GetObjectRef Error, packageObjectId == \(packageObjectId)")
                }
                var typeTags = [SuiTypeTag]()
                var arguments = [SuiCallArg]()
                switch typeArguments{
                case .Strings(let strs):
                   try strs.forEach {typeTags = try SuiTypeTag.parseStructTypeTag(str: $0)}
                case .TypeTags(let tags):
                    typeTags = tags
                }
                arguments = try SuiCallArgSerializer().serializeMoveCallArguments(txn: self).wait()
                seal.fulfill(.MoveCallTx(SuiMoveCallTx(package: packageObjectRef, module: module, function: function, typeArguments: typeTags, arguments: arguments)))
                
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    //mark
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = try SuiCallArgSerializer().extractObjectIds(txn: self).wait()
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}

//mark: move call 需要详细测试一下类型
extension SuiJsonValue{
    public func value() -> AnyObject{
        switch self{
        case .Str(let str):
            return str as AnyObject
        case .Array(let values):
            return values as AnyObject
        case .Boolean(let bool):
            return bool as AnyObject
        case .Number(let number):
            return number as AnyObject
        }
    }
    public func encode(type: SuiTypeTag,to writer: inout Data) throws{
        switch type {
        case .Bool:
            guard let booValue = value() as? Bool else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize SuiJsonValue Error, suiTypeTag: \(type)")
            }
            try booValue.serialize(to: &writer)
        case .UInt8:
            guard let number = value() as? String else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize SuiJsonValue Error, suiTypeTag: \(type)")
            }
            try UInt8(number)!.serialize(to: &writer)
        case .UInt64:
            guard let number = value() as? UInt64 else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize SuiJsonValue Error, suiTypeTag: \(type)")
            }
            try number.serialize(to: &writer)
        case .UInt128:
            guard let number = value() as? String else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize SuiJsonValue Error, suiTypeTag: \(type)")
            }
            try UInt128(number)!.serialize(to: &writer)
        case .Address:
            guard let address = value() as? String else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize SuiJsonValue Error, suiTypeTag: \(type)")
            }
            try SuiAddress(value: address).serialize(to: &writer)
        case .UInt16:
            guard let number = value() as? String else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize SuiJsonValue Error, suiTypeTag: \(type)")
            }
            try UInt16(number)!.serialize(to: &writer)
        case .UInt32:
            guard let number = value() as? String else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize SuiJsonValue Error, suiTypeTag: \(type)")
            }
            try UInt32(number)!.serialize(to: &writer)
        case .UInt256:
            guard let number = value() as? String else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize SuiJsonValue Error, suiTypeTag: \(type)")
            }
            try UInt256(number)!.serialize(to: &writer)
        default:
            break
        }
    }
}
