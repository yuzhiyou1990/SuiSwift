//
//  File.swift
//  
//
//  Created by li shuai on 2023/3/30.
//

import Foundation
import PromiseKit
import BigInt

public struct SuiObjectsToResolve{
    public let id: String
    public let input: SuiTransactionBlockInput
    public let normalizedType: SuiMoveNormalizedType?
}
public class SuiTransaction{
    public var sender: SuiAddress
    public var gasPrice: UInt64
    public var gasBudget: UInt64
    public var gasPayment: [SuiObjectRef]
    public static let MAX_GAS_OBJECTS = 256
    private var blockData: SuiTransactionBuilder?
    
    /** Returns an argument for the gas coin, to be used in a transaction. */
    public var gas: SuiTransactionArgumentType {
        return SuiTransactionArgumentType.GasCoin(.init())
    }
    
    public func setPatment(payment: [SuiObjectRef]){
        self.blockData?.gasConfig.payment = payment
    }
    
    public init(sender: SuiAddress, gasPrice: UInt64 = 1000, gasBudget: UInt64 = 2986000, gasPayment: [SuiObjectRef] = []) {
        self.sender = sender
        self.gasPrice = gasPrice
        self.gasBudget = gasBudget
        self.gasPayment = gasPayment
        self.blockData = SuiTransactionBuilder(sender: sender, gasConfig: SuiGasConfig(budget: "\(self.gasBudget)", price: "\(self.gasPrice)", payment: self.gasPayment, owner: self.sender))
    }
    /**
      * Add a new non-object input to the transaction.
      */
    public func setPure<T>(value: T, type: String? = nil) throws -> SuiTransactionArgumentType where T: BorshCodable{
        return try setInput(type: "pure", value: .CallArg(SuiInputs.Pure(value: value, type: type)))
    }
    /**
      * Add a new object input to the transaction using the fully-resolved object reference.
      * If you only have an object ID, use `builder.object(id)` instead.
      */
    public func setObjectRef(objectId: String, digest: String, version: UInt64) throws -> SuiTransactionArgumentType {
        return try setObject(value: .ImmOrOwned(.init(digest: digest, objectId: objectId, version: version)))
    }
    /**
       * Add a new shared object input to the transaction using the fully-resolved shared object reference.
       * If you only have an object ID, use `builder.object(id)` instead.
       */
    public func setSharedObjectRef(objectId: String, mutable: Bool, initialSharedVersion: UInt64) throws -> SuiTransactionArgumentType{
        return try setObject(value: .Shared(.init(objectId: objectId, initialSharedVersion: initialSharedVersion, mutable: mutable)))
    }
    
    public func setObject(value: SuiObjectArg) throws -> SuiTransactionArgumentType {
        return try setObject(jsonValue: .CallArg(.Object(value)))
    }
    
    public func setObjectStr(value: SuiObjectId) throws -> SuiTransactionArgumentType {
        return try setObject(jsonValue: .Str(value))
    }
    /**
       * Add a new object input to the transaction.
       */
    public func setObject(jsonValue: SuiJsonValue) throws -> SuiTransactionArgumentType {
        let id = SuiInputs.getIdFromCallArg(arg: jsonValue)
        // deduplicate
        let inserted = self.blockData?.inputs?.filter({ input in
            if let _value = input.value, input.type == "object" && id == SuiInputs.getIdFromCallArg(arg: _value){
                return true
            }
            return false
        })
        return inserted?.first != nil ? .TransactionBlockInput(inserted!.first!) : try setInput(type: "object", value: jsonValue)
    }
    /**
     * Dynamically create a new input, which is separate from the `input`. This is important
     * for generated clients to be able to define unique inputs that are non-overlapping with the
     * defined inputs.
     *
     * For `Uint8Array` type automatically convert the input into a `Pure` CallArg, since this
     * is the format required for custom serialization.
     *
     */
    public func setInput(type: String, value: SuiJsonValue?) throws -> SuiTransactionArgumentType {
        guard let _index = self.blockData?.inputs?.count else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("index is empty")
        }
        let input = SuiTransactionBlockInput(kind: "Input", index: UInt16(exactly: _index)!, value: value, type: type)
        
        self.blockData?.inputs?.append(input)
        return .TransactionBlockInput(input)
    }
    
    // methods
    @discardableResult
    public func splitCoins(transaction: SuiSplitCoinsTransaction) -> SuiTransactionArgumentType{
        self.addTransaction(transaction: transaction)
    }
    
    @discardableResult
    public func transferObjects(transaction: SuiTransferObjectsTransaction) -> SuiTransactionArgumentType{
        self.addTransaction(transaction: transaction)
    }
    
    @discardableResult
    public func moveCall(transaction: SuiMoveCallTransaction) -> SuiTransactionArgumentType{
        self.addTransaction(transaction: transaction)
    }
    
    @discardableResult
    public func publish(transaction: SuiPublishTransaction) -> SuiTransactionArgumentType{
        self.addTransaction(transaction: transaction)
    }
    
    @discardableResult
    public func upgrade(transaction: SuiUpgradeTransaction) -> SuiTransactionArgumentType{
        self.addTransaction(transaction: transaction)
    }
    
    @discardableResult
    public func makeMoveVec(transaction: SuiMakeMoveVecTransaction) -> SuiTransactionArgumentType{
        self.addTransaction(transaction: transaction)
    }
    
    @discardableResult
    public func mergeCoins(transaction: SuiMergeCoinsTransaction) -> SuiTransactionArgumentType{
        self.addTransaction(transaction: transaction)
    }
    
    @discardableResult
    public func addTransaction(transaction: SuiTransactionStruct) -> SuiTransactionArgumentType {
        self.blockData?.transactions?.append(transaction.inner())
        let length = self.blockData?.transactions?.count
        return .Result(.init(index: UInt16(length! - 1)))
    }
    
    public func build(provider: SuiJsonRpcProvider) -> Promise<Data>{
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                _ = try self.prepare(provider: provider).wait()
                guard let data = try self.blockData?.build() else{
                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("BlockData Build Error")
                }
                seal.fulfill(data)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func prepare(provider: SuiJsonRpcProvider) -> Promise<Bool>{
        return Promise { seal in
            DispatchQueue.global().async(.promise) {
                guard let blockData = self.blockData else{
                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("")
                }
                seal.fulfill(try blockData.prepare(provider: provider).wait())
            }.catch { error in
                seal.reject(error)
            }
        }
    }

    public func selectGasPayment(provider: SuiJsonRpcProvider) -> Promise<[SuiObjectRef]>{
        return Promise { seal in
            guard let gasOwner = self.blockData?.gasConfig.owner ?? self.blockData?.sender else {
                seal.reject(SuiError.BuildTransactionError.ConstructTransactionDataError("No gas owner found."))
                return
            }
            
            provider.getCoins(model: SuiRequestCoins(owner: gasOwner))
                .done { paginatedCoins in
                    guard let inputs = self.blockData?.inputs else {
                        throw SuiError.BuildTransactionError.ConstructTransactionDataError("BlockData inputs are empty.")
                    }
                    
                    let paymentCoins = paginatedCoins.data.filter { coin in
                        inputs.contains { input in
                            if case .CallArg(let _value) = input.value,
                               case .Object(let objectArg) = _value,
                               case .ImmOrOwned(let objRef) = objectArg {
                                return objRef.objectId == coin.coinObjectId
                            }
                            return false
                        }
                    }.map { coin in
                        SuiObjectRef(digest: coin.digest.value, objectId: coin.coinObjectId.value, version: coin.version.value())
                    }
                    
                    if paymentCoins.isEmpty {
                        throw SuiError.BuildTransactionError.ConstructTransactionDataError("No valid gas coins found for the transaction.")
                    }
                    
                    seal.fulfill(paymentCoins)
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }

}
// dapp
//extension SuiTransaction{
//    public func configTransactions(inputs: [[String: Any]], transactions: [[String: Any]]) throws{
//        try transactions.forEach { dic in
//            guard let kind = dic["kind"] as? String else{
//                throw SuiError.BuildTransactionError.InvalidSerializeData
//            }
//            switch kind{
//            case SuiMoveCallTransaction.kind:
//                guard let target = dic["target"] as? String,
//                      let argumentDics = dic["arguments"] as? [[String: Any]] else{
//                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid Target")
//                }
//                let arguments = try argumentDics.map { dic in
//                    guard let typeKind = dic["kind"] as? String else{
//                        throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid arguments")
//                    }
//                    switch typeKind{
//                    case SuiTransactionBlockInput.kind:
//                        guard let type = dic["type"] as? String,
//                              let index = dic["index"] as? UInt else{
//                            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid arguments")
//                        }
//                        if type == "object" {
//
//                        }
//                    }
//                    return try SuiTransactionArgumentType.type(dic: dic)
//                }
//                var moveCall = SuiMoveCallTransaction(target: target, arguments: arguments)
//            }
//        }
//    }
//}
//
extension SuiTransaction{
    public static func transactionSui(from: SuiAddress, to: SuiAddress, amount: BigUInt, gasPrice: UInt64 = 1, gasBudget: UInt64 = 50000000000, gasPayment: [SuiObjectRef] = []) throws -> SuiTransaction{
        let transactionSui = SuiTransaction(sender: from)
        transactionSui.setPatment(payment: gasPayment)
        let splitCoins = try transactionSui.splitCoins(transaction: .init(coin: transactionSui.gas, amounts: [transactionSui.setPure(value: UInt64(amount.description) ?? 0)]))
        try transactionSui.transferObjects(transaction: .init(objects: [splitCoins], address: transactionSui.setPure(value: to)))
        return transactionSui
    }
    
    public static func transactionCoin(from: SuiAddress, to: SuiAddress, amount: BigUInt, gasPrice: UInt64 = 1, gasBudget: UInt64 = 50000000000, gasPayment: [SuiObjectRef] = [], objectids: [SuiObjectRef]) throws -> SuiTransaction{
        let transactionSui = SuiTransaction(sender: from)
        transactionSui.setPatment(payment: gasPayment)
        guard objectids.count > 0 else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("invalid objectids")
        }
        let arguments = try objectids.map { ref in
            try transactionSui.setObject(jsonValue: .CallArg(.Object(.ImmOrOwned(ref))))
        }
        if arguments.count > 1 {
            transactionSui.mergeCoins(transaction: .init(destination: arguments[0], sources: Array(arguments[1..<arguments.count - 1])))
        }
        let splitCoins = try transactionSui.splitCoins(transaction: .init(coin: arguments[0], amounts: [transactionSui.setPure(value: UInt64(amount.description) ?? 0)]))
        try transactionSui.transferObjects(transaction: .init(objects: [splitCoins], address: transactionSui.setPure(value: to)))
        return transactionSui
    }
}
