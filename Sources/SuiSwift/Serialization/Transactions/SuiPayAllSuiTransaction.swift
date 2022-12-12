//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

public struct SuiPayAllSuiTransaction: SuiUnserializedSignableTransaction{
    public var inputCoins: [SuiObjectId]
    public var recipient: SuiAddress
    public var gasBudget: UInt64
    public init(inputCoins: [SuiObjectId], recipient: SuiAddress, gasBudget: UInt64) {
        self.inputCoins = inputCoins
        self.recipient = recipient
        self.gasBudget = gasBudget
    }
    public func bcsTransaction() -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async{
                let allPromise = self.inputCoins.compactMap{SuiJsonRpcProvider.shared.getObjectRef(objectId: $0)}
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
