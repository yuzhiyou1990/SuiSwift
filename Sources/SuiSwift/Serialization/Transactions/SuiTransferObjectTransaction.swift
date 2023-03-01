//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

public struct SuiTransferObjectTransaction: SuiUnserializedSignableTransaction{
    public var objectId: SuiObjectId
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public var gasPrice: UInt64?
    public var recipient: SuiAddress
    public var gasOwner: SuiAddress?
    
    public init(objectId: SuiObjectId, gasPayment: SuiObjectId? = nil, gasOwner: SuiAddress? = nil, recipient: SuiAddress, gasBudget: UInt64, gasPrice: UInt64? = nil) {
        self.objectId = objectId
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
        self.recipient = recipient
        self.gasPrice = gasPrice
        self.gasOwner = gasOwner
    }
    public func bcsTransaction(provider: SuiJsonRpcProvider) -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                guard let objectRef = try? provider.getObjectRef(objectId: objectId).wait() else{
                    throw SuiError.BCSError.SerializeError("Serialize SuiTransferObjectTransaction Error")
                }
                seal.fulfill(.TransferObjectTx(SuiTransferObjectTx(recipient: recipient.value, object_ref: objectRef)))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
        objectIds.append(objectId)
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}
