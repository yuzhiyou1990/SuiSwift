//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

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
    public func bcsTransaction() -> Promise<SuiTransaction> {
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
