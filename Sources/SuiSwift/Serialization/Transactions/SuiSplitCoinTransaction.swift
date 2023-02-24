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
    public var coinObjectId: SuiObjectId
    public var splitAmounts: [UInt64]
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public init(packageObjectId: SuiObjectId, coinObjectId: SuiObjectId, splitAmounts: [UInt64], gasPayment: SuiObjectId? = nil, gasBudget: UInt64) {
        self.packageObjectId = packageObjectId
        self.coinObjectId = coinObjectId
        self.splitAmounts = splitAmounts
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                guard let objectDataResponse = try? provider.getObject(objectId: coinObjectId).wait() else{
                    throw SuiError.BCSError.SerializeError("Serialize SuiSplitCoinTransaction GetObject Error, coinObjectId == \(coinObjectId)")
                }
                let typeArguments = TypeArguments.TypeTags([try getCoinStructTag(coin: objectDataResponse)])
                let arguments = [MoveCallArgument.JsonValue(.Str(coinObjectId)), MoveCallArgument.JsonValue(.Array(splitAmounts.map{.Number($0)}))]
                seal.fulfill(try SuiMoveCallTransaction(packageObjectId: packageObjectId,
                                                              module: PAY_MODULE_NAME,
                                                              function: PAY_JOIN_COIN_FUNC_NAME,
                                                              typeArguments: typeArguments,
                                                              arguments: arguments,
                                                              gasPayment: gasPayment,
                                                              gasBudget: gasBudget).bcsTransaction(provider: provider).wait())
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
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
