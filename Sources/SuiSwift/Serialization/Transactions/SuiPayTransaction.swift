//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

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
    public var gasPrice: UInt64?
    public init(inputCoins: [SuiObjectId], recipients: [SuiAddress], amounts: [UInt64], gasPayment: SuiObjectId? = nil, gasBudget: UInt64, gasPrice: UInt64? = nil) {
        self.inputCoins = inputCoins
        self.recipients = recipients
        self.amounts = amounts
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
        self.gasPrice = gasPrice
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async{
                let allPromise = self.inputCoins.compactMap{provider.getObjectRef(objectId: $0)}
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
