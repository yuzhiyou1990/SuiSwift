//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

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
    public func bcsTransaction() -> Promise<SuiTransaction> {
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
