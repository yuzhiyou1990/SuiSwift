//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/24.
//

import Foundation
import PromiseKit
import BigInt

public protocol SuiUnserializedSignableTransaction{
    //
    var gasBudget: UInt64{get}
    //
    func gasObjectId() -> SuiObjectId?
    //asynchronous
    func bcsTransaction() -> Promise<SuiTransaction>
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

extension SuiJsonRpcProvider{
    
    public func constructTransactionData(tx: SuiUnserializedSignableTransaction, signerAddress: SuiAddress) -> Promise<SuiTransactionData> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                var gasPaymentId: SuiObjectId? = tx.gasObjectId()
                if gasPaymentId == nil{
                    gasPaymentId = try self.selectGasPaymentForTransaction(tx: tx, signerAddress: signerAddress, amount: BigInt(tx.gasBudget)).wait()
                }
                let gasPayment =  try self.getObjectRef(objectId: gasPaymentId!).wait()
                let bcsTransaction = try tx.bcsTransaction().wait()
                seal.fulfill(SuiTransactionData(sender: signerAddress.value, gasBudget: tx.gasBudget, gasPrice: 1, kind: .Single(bcsTransaction), gasPayment: gasPayment!))
                
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    /**
       * Util function to select a coin for gas payment given an transaction, which will select
       * an arbitrary gas object owned by the address with balance greater than or equal to
       * `txn.data.gasBudget` that's not used in `txn` itself and the `exclude` list.
       *
       * @param txn the transaction for which the gas object is selected
       * @param signerAddress signer of the transaction
       * @param exclude additional object ids of the gas coins to exclude. Object ids that appear
       * in `txn` will be appended
       */
    public func selectGasPaymentForTransaction(tx: SuiUnserializedSignableTransaction, signerAddress: SuiAddress, amount: BigInt) -> Promise<SuiObjectId?>{
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                let ret = try tx.extractObjectIds()
                let coins = try self.selectCoinsWithBalanceGreaterThanOrEqual(address: signerAddress.value,
                                                                               amount: amount,
                                                                               typeArg: SUI_TYPE_ARG,
                                                                               exclude: ret).wait()
                seal.fulfill(coins.count > 0 ? SuiCoin.getID(data: coins[0]): nil)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
