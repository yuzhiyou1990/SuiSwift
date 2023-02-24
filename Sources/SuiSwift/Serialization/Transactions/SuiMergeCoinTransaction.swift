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
    public var coinToMerge: SuiObjectId
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public init(packageObjectId: SuiObjectId, primaryCoin: SuiObjectId, coinToMerge: SuiObjectId, gasPayment: SuiObjectId? = nil, gasBudget: UInt64) {
        self.packageObjectId = packageObjectId
        self.primaryCoin = primaryCoin
        self.coinToMerge = coinToMerge
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                guard let objectDataResponse = try? provider.getObject(objectId: coinToMerge).wait() else{
                    throw SuiError.BCSError.SerializeError("Serialize SuiMergeCoinTransaction GetObject Error, coinToMerge == \(coinToMerge)")
                }
                let typeArguments = TypeArguments.TypeTags([try getCoinStructTag(coin: objectDataResponse)])
                let arguments = [MoveCallArgument.JsonValue(.Str(primaryCoin)), MoveCallArgument.JsonValue(.Str(coinToMerge))]
                seal.fulfill( try SuiMoveCallTransaction(packageObjectId: packageObjectId,
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
        objectIds.append(primaryCoin)
        objectIds.append(coinToMerge)
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}
