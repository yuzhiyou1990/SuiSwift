//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

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
    public func bcsTransaction() -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async{
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
