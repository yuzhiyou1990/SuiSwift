//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/18.
//

import Foundation

public enum SuiCallArg{
    case Pure([UInt8])
    case Object(SuiObjectArg)
    case ObjVec([SuiObjectArg])
}

public enum SuiObjectArg{
    case ImmOrOwned(SuiObjectRef)
    case Shared(SuiSharedObjectRef)
}

public struct SuiSharedObjectRef{
    /** Hex code as string representing the object id */
    public var objectId: SuiAddress
    /** The version the object was shared at */
    public var initialSharedVersion: UInt64
    public var mutable: Bool
    public init(objectId: String, initialSharedVersion: UInt64, mutable: Bool) {
        self.objectId = try! SuiAddress(value: objectId)
        self.initialSharedVersion = initialSharedVersion
        self.mutable = mutable
    }
}
public struct SuiGasData{
    var payment: [SuiObjectRef]
    var owner: SuiAddress
    var price: UInt64
    var budget: UInt64
    init(payment: [SuiObjectRef], owner: SuiAddress, price: UInt64 = 1, budget: UInt64 = 10000) {
        self.payment = payment
        self.owner = owner
        self.price = price
        self.budget = budget
    }
}
public enum SuiTransactionExpiration{
    case None
    case Epoch(UInt64)
}

public enum SuiTransactionInner{
    case MoveCall(SuiMoveCallTransaction)
    case TransferObjects(SuiTransferObjectsTransaction)
    case SplitCoins(SuiSplitCoinsTransaction)
    case MergeCoins(SuiMergeCoinsTransaction)
    case Publish(SuiPublishTransaction)
    case MakeMoveVec(SuiMakeMoveVecTransaction)
    case Upgrade(SuiUpgradeTransaction)
}
public struct SuiProgrammableTransaction{
    public let inputs: [SuiCallArg]
    public let transactions: [SuiTransactionInner]
}

public enum SuiTransactionKind{
    case ProgrammableTransaction(SuiProgrammableTransaction)
    case ChangeEpoch
    case Genesis
    case ConsensusCommitPrologue
}
public struct SuiTransactionDataV1{
    public let kind: SuiTransactionKind
    public let sender: SuiAddress
    public let gasData: SuiGasData
    public let expiration: SuiTransactionExpiration
}

public enum SuiTransactionData{
    case V1(SuiTransactionDataV1)
}
