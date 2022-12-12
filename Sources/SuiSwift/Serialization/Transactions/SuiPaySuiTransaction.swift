//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

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
