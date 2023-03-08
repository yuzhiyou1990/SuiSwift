//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/29.
//

import Foundation
import PromiseKit

/**
 参考:https://github.com/MystenLabs/sui/blob/7a67d61e2a1b1e23281483e1eff24284e0bcacbe/sdk/typescript/src/signers/txn-data-serializers/call-arg-serializer.ts
 */

public class SuiCallArgSerializer{
    static let MOVE_CALL_SER_ERROR = "Move call argument serialization error:"
    var provider: SuiJsonRpcProvider
    init(provider: SuiJsonRpcProvider = SuiJsonRpcProvider.shared){
        self.provider = provider
    }
    
    public func extractObjectIds(txn: SuiMoveCallTransaction) -> Promise<[SuiObjectId]>{
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                let args = try self.serializeMoveCallArguments(txn: txn).wait()
                var objectArgs = [SuiObjectArg]()
                args.forEach { callArg in
                    switch callArg{
                    case .Object(let arg):
                        objectArgs.append(arg)
                    case .ObjVec(let args):
                        objectArgs.append(contentsOf: args)
                    case .Pure(_):
                        break
                    }
                }
                var objectIds = [SuiObjectId]()
                objectArgs.forEach { arg in
                    switch arg{
                    case .ImmOrOwned(let ref):
                        objectIds.append(ref.objectId.value)
                    case .Shared(let ref):
                        objectIds.append(ref.objectId.value)
                    }
                }
                seal.fulfill(objectIds)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func serializeMoveCallArguments(txn: SuiMoveCallTransaction) -> Promise<[SuiCallArg]> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                let userParams = try self.extractNormalizedFunctionParams(packageId: txn.packageObjectId, module: txn.module, functionName: txn.function).wait()
                let allCallPromise = userParams.enumerated().map { (index, param) in
                    self.newCallArg(expectedType: param, callArgument: txn.arguments[index])
                }
                var allCallArg = [SuiCallArg]()
                when(resolved: allCallPromise).wait().forEach { result in
                    switch result{
                    case .fulfilled(let arg):
                        allCallArg.append(arg)
                    case .rejected(let error):
                        debugPrint("newCallArg error: \(error)")
                    }
                }
                seal.fulfill(allCallArg)
                
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    private func extractNormalizedFunctionParams(packageId: SuiObjectId, module: String, functionName: String) -> Promise<[SuiMoveNormalizedType]> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                let normalized = try self.provider.getNormalizedMoveFunction(packageId: packageId.addHexPrefix(), moduleName: module, functionName: functionName).wait()
                let params = normalized.parameters
                // Entry functions can have a mutable reference to an instance of the TxContext
                // struct defined in the TxContext module as the last parameter. The caller of
                // the function does not need to pass it in as an argument.
                guard params.count > 0, self.isTxContext(param: params.last!) else{
                    seal.fulfill(params)
                    return
                }
                seal.fulfill(params[0..<(params.count - 1)].map{$0})
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    // https://github.com/MystenLabs/sui/pull/7765/files
    
    private func newCallArg(expectedType: SuiMoveNormalizedType, callArgument: MoveCallArgument) -> Promise<SuiCallArg>{
        return Promise { seal in
            switch callArgument {
            case .JsonValue(let argVal):
                let serType = try self.getPureSerializationType(normalizedType: expectedType, argVal: argVal)
                if serType != nil{
                    var data = Data()
                    try serType?.serialize(to: &data)
                    seal.fulfill(.Pure(data.bytes))
                    return
                }
                let structVal = expectedType.extractStructTag()
                if structVal != nil{
                    // argVal: objectId
                    guard let value = argVal.value() as? String else{
                        seal.reject(SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) expect the argument to be an object id string, got \(argVal.value())"))
                        return
                    }
                    seal.fulfill(.Object(try newObjectArg(objectId: value).wait()))
                    return
                }
                if case .MoveNormalizedTypeParameterType(_) = expectedType {
                    guard let value = argVal.value() as? String else{
                        seal.reject(SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) expect the typeParameter to be an object id string, got \(argVal.value())"))
                        return
                    }
                    seal.fulfill(.Object(try newObjectArg(objectId: value).wait()))
                    return
                }
                // Vector(struct{})
                if case .Vector(let suiMoveNormalizedTypeVector) = expectedType {
                    if case .MoveNormalizedStructType(_) = suiMoveNormalizedTypeVector.vector {
                        guard let value = argVal.value() as? Array<SuiJsonValue> else{
                            seal.reject(SuiError.DataSerializerError.ParseError("Expect \(argVal) to be a array, received \(type(of: argVal.value()))"))
                            return
                        }
                        let allCallPromise = value.filter{if let _ = $0.value() as? String{return true} else{ return false}}.map { jsonValue in
                            self.newObjectArg(objectId: jsonValue.value() as! String)
                        }
                        var objectArgs = [SuiObjectArg]()
                        when(resolved: allCallPromise).wait().forEach { result in
                            switch result{
                            case .fulfilled(let arg):
                                objectArgs.append(arg)
                            case .rejected(let error):
                                debugPrint("newObjectArg error: \(error)")
                            }
                        }
                        seal.fulfill(.ObjVec(objectArgs))
                        return
                    }
                }
                seal.reject(SuiError.DataSerializerError.ParseError("Unknown call arg type \(expectedType), for value \(argVal.value())"))
            case .PureArg(let array):
                seal.fulfill(.Pure(array))
            }
        }
    }
    
    private func newObjectArg(objectId: String) -> Promise<SuiObjectArg> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                let object = try self.provider.getObject(objectId: objectId).wait()
                let initialSharedVersion = object.getSharedObjectInitialVersion()
                if initialSharedVersion != nil{
                    // TODO: 需要检查
                    seal.fulfill(.Shared(SuiSharedObjectRef(objectId: objectId, initialSharedVersion: UInt64(initialSharedVersion!), mutable: false)))
                    return
                }
                seal.fulfill(.ImmOrOwned(object.getObjectReference()!))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    /**
       *
       * @param argVal used to do additional data validation to make sure the argVal
       * matches the normalized Move types. If `argVal === undefined`, the data validation
       * will be skipped. This is useful in the case where `normalizedType` is a vector<T>
       * and `argVal` is an empty array, the data validation for the inner types will be skipped.
       */
    private func getPureSerializationType(normalizedType: SuiMoveNormalizedType, argVal: SuiJsonValue) throws -> BorshSerializable?{
        let allowedTypes = ["Address", "Bool", "U8", "U16", "U32", "U64", "U128", "U256"]
        switch normalizedType {
        case .Str(let string):
            guard allowedTypes.contains(string), let bcsValue = SuiTypeTag.parseArgWithType(normalizedType: string.lowercased(), jsonValue: argVal)  else{
                throw SuiError.DataSerializerError.ParseError("unknown pure normalized type \(string)")
            }
            return bcsValue
        case .Vector(let suiMoveNormalizedTypeVector):
            if case .Str(let string) = suiMoveNormalizedTypeVector.vector, string == "U8"{
                if case .Str(let str) = argVal {
                    return str
                } else {return nil}
            }
            if case .Array(let values) = argVal{
                var argsBCS = Array<BorshSerializable>()
                for value in values {
                    let inner = try self.getPureSerializationType(normalizedType: suiMoveNormalizedTypeVector.vector, argVal: value)
                    if inner != nil{
                        argsBCS.append(inner!)
                        
                    } else {return nil}
                }
            } else{
                throw SuiError.DataSerializerError.ParseError("Expect \(argVal) to be a array")
            }
        
        case .MoveNormalizedStructType(let suiMoveNormalizedStructType):
            if let value = argVal.value() as? String {
                if SuiStructType.RESOLVED_ASCII_STR == suiMoveNormalizedStructType.structType{
                    return ASCIIString(value: value)
                } else if SuiStructType.RESOLVED_UTF8_STR == suiMoveNormalizedStructType.structType{
                    return value
                } else if SuiStructType.RESOLVED_SUI_ID == suiMoveNormalizedStructType.structType{
                    return try SuiAddress(value: value)
                } else if SuiStructType.RESOLVED_STD_OPTION == suiMoveNormalizedStructType.structType{
                    let argumentType = suiMoveNormalizedStructType.structType.type_arguments[0]
                    return try getPureSerializationType(normalizedType: argumentType, argVal: argVal)
                }
            }
        default:
            return nil
        }
        return nil
    }
    private func isTxContext(param: SuiMoveNormalizedType) -> Bool{
        let structType = param.extractStructTag()?.structType
        guard case .MutableReference(_) = param,
              structType?.address == "0x2",
              structType?.module == "tx_context",
              structType?.name == "TxContext" else{
            return false
        }
        return true
    }
}

extension SuiTypeTag{
    // normalizedType === 'string
    public static func parseArgWithType(normalizedType type: String, jsonValue arg: SuiJsonValue) -> BorshSerializable?{
        if type == "address" {
            guard let value =  arg.value() as? String,
                  let address = try? SuiAddress(value: value) else{
                return nil
            }
            return address
        } else if type == "bool" {
            guard let value = arg.value() as? Bool else{
                return nil
            }
            return value
        } else if type == "u8" {
            return nil
        } else if type == "u16" {
            return nil
        } else if type == "u32" {
            return nil
        } else if type == "u64" {
            guard let value = arg.value() as? String else{
                return nil
            }
            return Int64("\(value)")?.unsigned
        } else if type == "u128" {
            return nil
        } else if type == "u256" {
            return nil
        }
        return nil
    }
}
extension Int64 {
    var unsigned: UInt64 {
        let valuePointer = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee }
    }
}

extension UInt64 {
    var signed: Int64 {
        let valuePointer = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: Int64.self, capacity: 1) { $0.pointee }
    }
}
