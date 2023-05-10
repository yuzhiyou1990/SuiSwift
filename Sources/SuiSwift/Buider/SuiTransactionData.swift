//
//  File.swift
//  
//
//  Created by li shuai on 2023/3/30.
//

import Foundation
import PromiseKit

public class SuiTransactionBuilder{
    public var version: Int
    public var sender: SuiAddress?
    public var expiration: SuiTransactionExpiration?
    public var gasConfig: SuiGasConfig
    public var inputs: [SuiTransactionBlockInput]?
    public var transactions: [SuiTransactionInner]?
    public init(version: Int = 1, sender: SuiAddress? = nil, expiration: SuiTransactionExpiration? = nil, gasConfig: SuiGasConfig = SuiGasConfig(), inputs: [SuiTransactionBlockInput]? = [SuiTransactionBlockInput](), transactions: [SuiTransactionInner]? = [SuiTransactionInner]()) {
        self.version = version
        self.sender = sender
        self.expiration = expiration
        self.gasConfig = gasConfig
        self.inputs = inputs
        self.transactions = transactions
    }
    public func signWithKeypair(keypair: SuiKeypair) throws -> SuiExecuteTransactionBlock{
        let serializeTransactionData = try self.build()
        return try serializeTransactionData.signTxnBytesWithKeypair(keypair: keypair)
    }
    public func build() throws -> Data{
         guard let sender = self.sender else{
             throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing sender")
         }
         guard let price = self.gasConfig.price, let budget = self.gasConfig.budget else{
             throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing gasConfig")
         }
         guard let inputs = self.inputs else{
             throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing inputs")
         }
         guard let transactions = self.transactions else{
             throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing transactions")
         }
         let values = try inputs.map { input in
             guard case .CallArg(let callArg) = input.value else{
                 throw SuiError.BuildTransactionError.ConstructTransactionDataError("invalid input value")
             }
             return callArg
         }
         let programmableTransaction = SuiProgrammableTransaction(inputs: values, transactions: transactions)
         let transactionData = SuiTransactionData.V1(SuiTransactionDataV1(kind: .ProgrammableTransaction(programmableTransaction), sender: sender, gasData: SuiGasData(payment: self.gasConfig.payment, owner: gasConfig.owner ?? sender, price: UInt64(price)!, budget: UInt64(budget)!), expiration: self.expiration ?? .None))
         var data = Data()
         try transactionData.serialize(to: &data)
         return data
    }
    
    public func updateInput(input: SuiTransactionBlockInput) throws{
        guard let inputs = self.inputs else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing inputs")
        }
        guard let index = inputs.map({ $0.index }).filter({ $0 == input.index }).first else {
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("UpdateInput Error, invalid index")
        }
        self.inputs![Int(index)].value = input.value
    }
}

extension SuiTransactionBuilder{
    // prepare
    public func prepare(provider: SuiJsonRpcProvider) -> Promise<Bool>{
        return Promise { seal in
            DispatchQueue.global().async(.promise) {
                var objectsToResolve = [SuiObjectsToResolve]()
                var moveModulesToResolve = [SuiMoveCallTransaction]()
                try self.resolveTransactions(moveModulesToResolve: &moveModulesToResolve, objectsToResolve: &objectsToResolve)

                for moveCall in moveModulesToResolve {
                    let params = try provider.getNormalizedMoveFunctionParams(target: moveCall.target).wait()
                    guard params.count == moveCall.arguments.count else {
                        throw SuiError.BuildTransactionError.ConstructTransactionDataError("Incorrect number of arguments.")
                    }
                    try self.serializationPureType(apiMoveParams: params, originMoveArguments: moveCall.arguments, objectsToResolve: &objectsToResolve)
                }

                if objectsToResolve.count > 0{
                    let dedupedIds = Array(Set(objectsToResolve.map { $0.id }))
                    let objects = try provider.multiGetObjects(model: SuiMultiGetObjects(ids: dedupedIds, option: SuiObjectDataOptions(showType: true, showOwner: true))).wait()
                    let objectsById = Dictionary(uniqueKeysWithValues: dedupedIds.enumerated().map { (index, element) in
                        return (element, objects[index])
                    })
                    let invalidObjects = objectsById.compactMap { _, value in
                        guard let _ = value.error else {
                            return nil
                        }
                        return value
                    } as [SuiObjectResponse]
                    if invalidObjects.count > 0{
                        throw SuiError.BuildTransactionError.ConstructTransactionDataError("input objects are not invalid:")
                    }
                    for objectsToResolve in objectsToResolve {
                        if let object = objectsById[objectsToResolve.id] {
                            var input = objectsToResolve.input
                            let normalizedType = objectsToResolve.normalizedType
                            let initialSharedVersion =  object.getSharedObjectInitialVersion()
                            if let version = initialSharedVersion, let value = input.value {
                                let mutable = value.isMutableSharedObjectInput() || ((normalizedType != nil) && (normalizedType?.extractMutableReference() != nil))
                                input.value = .CallArg(.Object(.Shared(.init(objectId: objectsToResolve.id, initialSharedVersion: UInt64(version), mutable: mutable))))
                            } else if let objectRef = object.getObjectReference() {
                                input.value = .CallArg(.Object(.ImmOrOwned(objectRef)))
                            }
                            try self.updateInput(input: input)
                        }
                    }
                    seal.fulfill(true)
                } else {
                    seal.fulfill(true)
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    public func resolveTransactions(moveModulesToResolve: inout [SuiMoveCallTransaction], objectsToResolve: inout [SuiObjectsToResolve]) throws{
        try transactions?.forEach({ transactionInner in
            if case .MoveCall(let moveCallTransaction) = transactionInner {
                var needsResolution = false
                for argument in moveCallTransaction.arguments {
                    if case .TransactionBlockInput(let input) = argument {
                        switch input.value{
                        case .CallArg(_):
                            needsResolution = false
                        default:
                            needsResolution = true
                        }
                    }
                    if needsResolution {break} else {continue}
                }
                if needsResolution {
                    moveModulesToResolve.append(moveCallTransaction)
                }
                return
            }
            try transactionInner.encodeInput(inputs: &self.inputs, objectsToResolve: &objectsToResolve)
        })
    }
}

extension SuiTransactionStruct{
    public func handleResolve(inputs: inout [SuiTransactionBlockInput]?, index: Int, objectsToResolve: inout [SuiObjectsToResolve]) throws {
        guard let _inputs = inputs, index <= _inputs.count - 1 else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing input \(index)")
        }
        let input = _inputs[index]
        guard let value = input.value else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Unexpected input format.")
        }
        switch value{
        case .CallArg(_):
            return
        case .Str(let _str):
            if input.type == "object"{
                objectsToResolve.append(SuiObjectsToResolve(id: _str, input: inputs![index], normalizedType: nil))
                return
            }
            if input.type == "pure"{
                var data = Data()
                try SuiInputs.PureWithJsonValue(value: value, data: &data)
                inputs?[Int(input.index)].value = SuiJsonValue.CallArg(.Pure(data.bytes))
            }
        default:
            var data = Data()
            try SuiInputs.PureWithJsonValue(value: value, data: &data)
            inputs?[Int(input.index)].value = SuiJsonValue.CallArg(.Pure(data.bytes))
        }
    }
}

extension SuiTransactionBuilder{
    // 把input基本类型转为 callArg
    public func serializationPureType(apiMoveParams: [SuiMoveNormalizedType], originMoveArguments: [SuiTransactionArgumentType], objectsToResolve: inout [SuiObjectsToResolve]) throws{
        guard let inputs = self.inputs else {
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Movecall InputValue Is Invalid")
        }
        for (index, param) in apiMoveParams.enumerated() {
            if case .TransactionBlockInput(let input) = originMoveArguments[index], let inputValue = inputs[Int(input.index)].value {
                if case .CallArg(_) = inputValue {
                    continue
                }
                let serType = try SuiTransactionBuilder.getPureSerializationType(normalizedType: param, argVal: inputValue)
                if let pureType = serType.flatMap({ $0 }) {
                    self.inputs?[Int(input.index)].value = .CallArg(.Pure(pureType))
                    continue
                }
                if let _ = param.extractStructTag(){
                    guard let value = inputValue.value() as? String else {
                        throw SuiError.DataSerializerError.ParseError("expect the argument to be an object id string, got {\(inputValue.value())}")
                    }
                    objectsToResolve.append(SuiObjectsToResolve(id: value, input: self.inputs![Int(input.index)], normalizedType: param))
                    continue
                }
                if case .MoveNormalizedTypeParameterType(_) = param{
                    guard let value = inputValue.value() as? String else {
                        throw SuiError.DataSerializerError.ParseError("expect the argument to be an object id string, got {\(inputValue.value())}")
                    }
                    objectsToResolve.append(SuiObjectsToResolve(id: value, input: self.inputs![Int(input.index)], normalizedType: param))
                    continue
                }
            }
            continue
        }
    }
    /**
       *
       * @param argVal used to do additional data validation to make sure the argVal
       * matches the normalized Move types. If `argVal === undefined`, the data validation
       * will be skipped. This is useful in the case where `normalizedType` is a vector<T>
       * and `argVal` is an empty array, the data validation for the inner types will be skipped.
       */
    public static func getPureSerializationType(normalizedType: SuiMoveNormalizedType, argVal: SuiJsonValue) throws -> [UInt8]?{
        let allowedTypes = ["Address", "Bool", "U8", "U16", "U32", "U64", "U128", "U256"]
        switch normalizedType {
        case .Str(let string):
            guard allowedTypes.contains(string), let bcsValue = SuiParseTypeTag.parseArgWithType(normalizedType: string.lowercased(), jsonValue: argVal)  else{
                throw SuiError.DataSerializerError.ParseError("unknown pure normalized type \(string)")
            }
            var data = Data()
            try bcsValue.serialize(to: &data)
            return data.bytes
        case .Vector(let suiMoveNormalizedTypeVector):
            if case .Str(let string) = suiMoveNormalizedTypeVector.vector, string == "U8"{
                if case .Str(let str) = argVal {
                    var data = Data()
                    try str.serialize(to: &data)
                    return data.bytes
                }
            }
            if case .Array(let values) = argVal{
                var argsBCS = [UInt8]()
                for value in values {
                    let inner = try self.getPureSerializationType(normalizedType: suiMoveNormalizedTypeVector.vector, argVal: value)
                    if inner != nil{
                        argsBCS.append(contentsOf: inner!)
                        
                    } else {return nil}
                }
                var data = Data()
                try argsBCS.serialize(to: &data)
                return data.bytes
                
            } else{
                throw SuiError.DataSerializerError.ParseError("Expect \(argVal) to be a array")
            }
            
        case .MoveNormalizedStructType(let suiMoveNormalizedStructType):
            if let value = argVal.value() as? String {
                if SuiStructType.RESOLVED_ASCII_STR == suiMoveNormalizedStructType.structType{
                    var data = Data()
                    try ASCIIString(value: value).serialize(to: &data)
                    return data.bytes
                } else if SuiStructType.RESOLVED_UTF8_STR == suiMoveNormalizedStructType.structType{
                    var data = Data()
                    try value.serialize(to: &data)
                    return data.bytes
                } else if SuiStructType.RESOLVED_SUI_ID == suiMoveNormalizedStructType.structType{
                    var data = Data()
                    try SuiAddress(value: value).serialize(to: &data)
                    return data.bytes
                } else if SuiStructType.RESOLVED_STD_OPTION == suiMoveNormalizedStructType.structType{
                    let argumentType = suiMoveNormalizedStructType.structType.typeArguments[0]
                    return try getPureSerializationType(normalizedType: argumentType, argVal: argVal)
                }
            }
        default:
            return nil
        }
        return nil
    }
}
