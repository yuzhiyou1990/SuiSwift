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
                    case .Shared_Deprecated(_):
                        break
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
                    self.newCallArg(expectedType: param, argVal: txn.arguments[index])
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
    
    private func newCallArg(expectedType: SuiMoveNormalizedType, argVal: SuiJsonValue) -> Promise<SuiCallArg>{
        return Promise { seal in
            let serType = try self.getPureSerializationType(normalizedType: expectedType, argVal: argVal)
            if serType != nil{
                var data = Data()
                try serType?.serialize(to: &data)
                seal.fulfill(.Pure(data.bytes))
                return
            }
            let structVal = expectedType.extractStructTag()
            if structVal != nil{
                if case .MoveNormalizedTypeParameterType(_) = expectedType {
                    // argVal: objectId
                    guard let value = argVal.value() as? String else{
                        seal.reject(SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) expect the argument to be an object id string, got {\(argVal.value()) null 2}"))
                        return
                    }
                    seal.fulfill(.Object(try newObjectArg(objectId: value).wait()))
                    return
                }
            }
            if case .Vector(let suiMoveNormalizedTypeVector) = expectedType {
                if case .MoveNormalizedStructType(_) = suiMoveNormalizedTypeVector.vector {
                    guard let value = argVal.value() as? Array<String> else{
                        seal.reject(SuiError.DataSerializerError.ParseError("Expect \(argVal) to be a array, received \(type(of: argVal.value()))"))
                        return
                    }
                    let allCallPromise = value.map { objectId in
                        self.newObjectArg(objectId: objectId)
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
        }
    }
    
    private func newObjectArg(objectId: String) -> Promise<SuiObjectArg> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                let object = try self.provider.getObject(objectId: objectId).wait()
                let initialSharedVersion = object.getSharedObjectInitialVersion()
                if initialSharedVersion != nil{
                    seal.fulfill(.Shared(SuiSharedObjectRef(objectId: objectId, initialSharedVersion: UInt64(initialSharedVersion!))))
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
    private func getPureSerializationType(normalizedType: SuiMoveNormalizedType, argVal: SuiJsonValue?) throws -> SuiTypeArgument?{
        let allowedTypes = ["Address", "Bool", "U8", "U16", "U32", "U64", "U128", "U256"]
        
        switch normalizedType {
        case .Str(let string):
            guard allowedTypes.contains(string), let type = SuiTypeTag.parseBase(str: string.lowercased())  else{
                throw SuiError.DataSerializerError.ParseError("unknown pure normalized type \(string)")
            }
            return .TypeTag(type, argVal)
        case .Vector(let suiMoveNormalizedTypeVector):
            if case .Str(let string) = suiMoveNormalizedTypeVector.vector, string == "U8"{
                if argVal == nil{
                    return .String(nil)
                } else {
                    if case .Str(let str) = argVal! {
                        return .String(str)
                    }
                }
            }
            var jsonValue: SuiJsonValue?
            if argVal != nil {
                if case .Array(let values) = argVal!{
                    jsonValue = values.first
                } else{
                    throw SuiError.DataSerializerError.ParseError("Expect \(argVal!) to be a array")
                }
            }
            let innerType = try self.getPureSerializationType(normalizedType: suiMoveNormalizedTypeVector.vector, argVal: jsonValue)
            return innerType != nil ? .Vector(innerType) : nil
            
        case .MoveNormalizedStructType(let suiMoveNormalizedStructType):
            let value = argVal?.value() as? String
            if SuiStructType.RESOLVED_ASCII_STR == suiMoveNormalizedStructType.structType{
                return .String(value)
            } else if SuiStructType.RESOLVED_UTF8_STR == suiMoveNormalizedStructType.structType{
                return .Utf8string(value)
            } else if SuiStructType.RESOLVED_SUI_ID == suiMoveNormalizedStructType.structType{
                return .Address(value)
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
