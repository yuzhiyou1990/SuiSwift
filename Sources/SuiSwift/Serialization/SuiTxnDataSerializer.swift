//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/1.
//

import Foundation
import PromiseKit

public protocol SuiUnserializedSignableTransaction{
    //
    var gasBudget: UInt64{get}
    //
    func gasObjectId() -> SuiObjectId?
    //asynchronous
    func bcsTransaction(provider: SuiJsonRpcProvider?) -> Promise<SuiTransaction>
    /**
      * Returns a list of object ids used in the transaction, including the gas payment object
      */
    func extractObjectIds() throws -> [SuiObjectId]
}

// SuiMergeCoinTransaction || SuiSplitCoinTransaction
extension SuiUnserializedSignableTransaction{
    func getCoinStructTag(coin: SuiGetObjectDataResponse) throws -> SuiTypeTag{
        guard let coinTypeArg = SuiCoin.getCoinTypeArg(data: coin),
              let arg = SuiCoin.getCoinStructTag(coinTypeArg: coinTypeArg) else{
            throw SuiError.BCSError.SerializeError("Object \(coin.getObjectId() ?? "null") is not a valid coin type")
        }
        return .Struct(arg)
    }
}

public struct SuiPublishTransaction: SuiUnserializedSignableTransaction{
    public enum CompiledModules{
        case Array([String])
        case Arrayx([[UInt64]])
    }
    public var compiledModules: CompiledModules
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public init(compiledModules: CompiledModules, gasPayment: SuiObjectId? = nil, gasBudget: UInt64) {
        self.compiledModules = compiledModules
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(){
                switch compiledModules {
                case .Array(_):
                    seal.reject(SuiError.BCSError.SerializeError("Serialize SuiPublishTransaction Error"))
                case .Arrayx(let array):
                    seal.fulfill(.PublishTx(SuiPublishTx(modules: array.map{$0.map({UInt8($0)})})))
                }
            }
        }
    }
    
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}

public struct SuiMergeCoinTransaction: SuiUnserializedSignableTransaction{
    public var packageObjectId: SuiObjectId
    public var primaryCoin: SuiObjectId
    public var coinToMerge: SuiGetObjectDataResponse
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    
    public init(packageObjectId: SuiObjectId, primaryCoin: SuiObjectId, coinToMerge: SuiGetObjectDataResponse, gasPayment: SuiObjectId? = nil, gasBudget: UInt64) {
        self.packageObjectId = packageObjectId
        self.primaryCoin = primaryCoin
        self.coinToMerge = coinToMerge
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                guard let id = coinToMerge.getObjectId() else{
                    throw SuiError.BCSError.SerializeError("Serialize SuiMergeCoinTransaction Error")
                }
                seal.fulfill( try SuiMoveCallTransaction(packageObjectId: packageObjectId,
                                                    module: PAY_MODULE_NAME,
                                                    function: PAY_JOIN_COIN_FUNC_NAME,
                                                    typeArguments: .TypeTags([try getCoinStructTag(coin: coinToMerge)]),
                                                    arguments: [.Str(primaryCoin), .Str(id)],
                                                    gasPayment: gasPayment,
                                                    gasBudget: gasBudget).bcsTransaction().wait())
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
        guard let coinToMergeId = coinToMerge.getObjectId() else{
            throw SuiError.BCSError.SerializeError("Serialize SuiMergeCoinTransaction Error")
        }
        objectIds.append(primaryCoin)
        objectIds.append(coinToMergeId)
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}

public struct SuiSplitCoinTransaction: SuiUnserializedSignableTransaction{
    
    public var packageObjectId: SuiObjectId
    public var coinObject: SuiGetObjectDataResponse
    public var splitAmounts: [UInt64]
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public init(packageObjectId: SuiObjectId, coinObject: SuiGetObjectDataResponse, splitAmounts: [UInt64], gasPayment: SuiObjectId? = nil, gasBudget: UInt64) {
        self.packageObjectId = packageObjectId
        self.coinObject = coinObject
        self.splitAmounts = splitAmounts
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                guard let id = coinObject.getObjectId() else{
                    throw SuiError.BCSError.SerializeError("Serialize SuiSplitCoinTransaction Error")
                }
                seal.fulfill(try SuiMoveCallTransaction(packageObjectId: packageObjectId,
                                                              module: PAY_MODULE_NAME,
                                                              function: PAY_JOIN_COIN_FUNC_NAME,
                                                              typeArguments: .TypeTags([try getCoinStructTag(coin: coinObject)]),
                                                              arguments: [.Str(id), .Array(splitAmounts.map{.Number($0)})],
                                                              gasPayment: gasPayment,
                                                              gasBudget: gasBudget).bcsTransaction().wait())
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
        guard let coinObjectId = coinObject.getObjectId() else{
            throw SuiError.BCSError.SerializeError("Serialize SuiSplitCoinTransaction Error")
        }
        objectIds.append(coinObjectId)
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}

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
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                guard let packageObjectRef = try? provider?.getObjectRef(objectId: packageObjectId).wait() else{
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
        var objectIds = [SuiObjectId]()
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}


public struct SuiTransferObjectTransaction: SuiUnserializedSignableTransaction{
    public var objectId: SuiObjectId
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public var recipient: SuiAddress
    public init(objectId: SuiObjectId, gasPayment: SuiObjectId? = nil, gasBudget: UInt64, recipient: SuiAddress) {
        self.objectId = objectId
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
        self.recipient = recipient
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                guard let objectRef = try? provider?.getObjectRef(objectId: objectId).wait() else{
                    throw SuiError.BCSError.SerializeError("Serialize SuiTransferObjectTransaction Error")
                }
                seal.fulfill(.TransferObjectTx(SuiTransferObjectTx(recipient: recipient.value, object_ref: objectRef)))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
        objectIds.append(objectId)
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}

public struct SuiTransferSuiTransaction: SuiUnserializedSignableTransaction{
    public var suiObjectId: SuiObjectId
    public var gasBudget: UInt64
    public var recipient: SuiAddress
    public var amount: UInt64?
    public init(suiObjectId: SuiObjectId, gasBudget: UInt64, recipient: SuiAddress, amount: UInt64? = nil) {
        self.suiObjectId = suiObjectId
        self.gasBudget = gasBudget
        self.recipient = recipient
        self.amount = amount
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(){
                seal.fulfill(.TransferSuiTx(SuiTransferSuiTx(recipient: recipient.value, amount: amount)))
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
        objectIds.append(suiObjectId)
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return suiObjectId
    }
}

/// Send Coin<T> to a list of addresses, where `T` can be any coin type, following a list of amounts,
/// The object specified in the `gas` field will be used to pay the gas fee for the transaction.
/// The gas object can not appear in `input_coins`. If the gas object is not specified, the RPC server
/// will auto-select one.
/// 
public struct SuiPayTransaction: SuiUnserializedSignableTransaction{
    public var inputCoins: [SuiObjectId]
    public var recipients: [SuiAddress]
    public var amounts: [UInt64]
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public init(inputCoins: [SuiObjectId], recipients: [SuiAddress], amounts: [UInt64], gasPayment: SuiObjectId? = nil, gasBudget: UInt64) {
        self.inputCoins = inputCoins
        self.recipients = recipients
        self.amounts = amounts
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(){
                let allPromise = self.inputCoins.compactMap{provider?.getObjectRef(objectId: $0)}
                var inputCoinRefs = [SuiObjectRef]()
                when(resolved: allPromise).wait().forEach({ result in
                    switch result{
                    case .fulfilled(let objectRef):
                        inputCoinRefs.append(objectRef!)
                    case .rejected(_):
                        seal.reject(SuiError.BCSError.SerializeError("Serialize SuiPayTransaction Error"))
                    }
                })
                seal.fulfill(.PayTx(SuiPayTx(coins: inputCoinRefs, recipients: recipients.map{$0.value}, amounts: amounts)))
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
        for id in inputCoins.map({$0}){
            objectIds.append(id)
        }
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}

public struct SuiPaySuiTransaction: SuiUnserializedSignableTransaction{
    public var inputCoins: [SuiObjectId]
    public var recipients: [SuiAddress]
    public var amounts: [UInt64]
    public var gasBudget: UInt64
    public init(inputCoins: [SuiObjectId], recipients: [SuiAddress], amounts: [UInt64], gasBudget: UInt64) {
        self.inputCoins = inputCoins
        self.recipients = recipients
        self.amounts = amounts
        self.gasBudget = gasBudget
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(){
                let allPromise = self.inputCoins.compactMap{provider?.getObjectRef(objectId: $0)}
                var inputCoinRefs = [SuiObjectRef?]()
                when(resolved: allPromise).wait().forEach({ result in
                    switch result{
                    case .fulfilled(let objectRef):
                        inputCoinRefs.append(objectRef)
                    case .rejected(_):
                        seal.reject(SuiError.BCSError.SerializeError("Serialize SuiPaySuiTransaction Error"))
                    }
                })
                seal.fulfill(.PaySuiTx(SuiPaySuiTx(coins: inputCoinRefs.compactMap{$0}, recipients: recipients.map{$0.value}, amounts: amounts)))
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        return []
    }
    public func gasObjectId() -> SuiObjectId? {
        return inputCoins.first
    }
}

public struct SuiPayAllSuiTransaction: SuiUnserializedSignableTransaction{
    public var inputCoins: [SuiObjectId]
    public var recipient: SuiAddress
    public var gasBudget: UInt64
    public init(inputCoins: [SuiObjectId], recipient: SuiAddress, gasBudget: UInt64) {
        self.inputCoins = inputCoins
        self.recipient = recipient
        self.gasBudget = gasBudget
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider? = SuiJsonRpcProvider()) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(){
                let allPromise = self.inputCoins.compactMap{provider?.getObjectRef(objectId: $0)}
                var inputCoinRefs = [SuiObjectRef?]()
                when(resolved: allPromise).wait().forEach({ result in
                    switch result{
                    case .fulfilled(let objectRef):
                        inputCoinRefs.append(objectRef)
                    case .rejected(_):
                        seal.reject(SuiError.BCSError.SerializeError("Serialize SuiPayAllSuiTransaction Error"))
                    }
                })
                seal.fulfill(.PayAllSuiTx(SuiPayAllSuiTx(coins: inputCoinRefs.compactMap{$0}, recipient: recipient.value)))
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        return []
    }
    public func gasObjectId() -> SuiObjectId? {
        return inputCoins.first
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
