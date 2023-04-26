//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/10.
//

import Foundation
public struct SuiGasCoinArgumentType{
    public let kind: String = "GasCoin"
}
public struct SuiTransactionBlockInput{
    public let kind: String = "Input"
    public var index: UInt16
    public var value: SuiJsonValue? = nil
    public var type: String? = nil
    public init(kind: String = "Input", index: UInt16, value: SuiJsonValue? = nil, type: String? = nil) {
        self.index = index
        self.value = value
        self.type = type
    }
}
public struct SuiResultArgumentType{
    public let kind: String = "Result"
    public let index: UInt16
}
public struct SuiNestedResultArgumentType{
    public let kind: String = "NestedResult"
    public let index: UInt16
    public let resultIndex: UInt16
}

public enum SuiTransactionArgumentType{
    case GasCoin(SuiGasCoinArgumentType)
    case TransactionBlockInput(SuiTransactionBlockInput)
    case Result(SuiResultArgumentType)
    case NestedResult(SuiNestedResultArgumentType)
}

public struct SuiPureTransactionArgument{
    public let kind: String = "pure"
    public let type: String
    public init(type: String) {
        self.type = type
    }
}
// Transactions
public protocol SuiTransactionStruct{
    func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws
    func inner() -> SuiTransactionInner
}

public struct SuiProgrammableCallInner{
    public let package: String
    public let module: String
    public let function: String
    public var typeArguments: [SuiTypeTag]?
    public var arguments: [SuiTransactionArgumentType]
}

public struct SuiMoveCallTransaction: SuiTransactionStruct{
    public let kind: String = "MoveCall"
    public var target: String = ""
    public var typeArguments: [String]?
    public var arguments: [SuiTransactionArgumentType]
    public func inner() -> SuiTransactionInner {
        return .MoveCall(self)
    }
}

public struct SuiTransferObjectsTransaction: SuiTransactionStruct{
    public let kind: String = "TransferObjects"
    public let objects: [SuiTransactionArgumentType]
    public let address: SuiTransactionArgumentType
    public func inner() -> SuiTransactionInner {
        return .TransferObjects(self)
    }
}

public struct SuiSplitCoinsTransaction: SuiTransactionStruct{
    public let kind: String = "SplitCoins"
    public let coin: SuiTransactionArgumentType
    public let amounts: [SuiTransactionArgumentType]
    public func inner() -> SuiTransactionInner {
        return .SplitCoins(self)
    }
}

public struct SuiMergeCoinsTransaction: SuiTransactionStruct{
    public let kind: String = "MergeCoins"
    public let destination: SuiTransactionArgumentType
    public let sources: [SuiTransactionArgumentType]
    public func inner() -> SuiTransactionInner {
        return .MergeCoins(self)
    }
}

public struct SuiMakeMoveVecTransaction: SuiTransactionStruct{
    public let kind: String = "MakeMoveVec"
    public let type: [SuiTypeTag]?
    public let objects: [SuiTransactionArgumentType]
    public func inner() -> SuiTransactionInner {
        return .MakeMoveVec(self)
    }
}


public struct SuiPublishTransaction: SuiTransactionStruct{
    public let kind: String = "Publish"
    public let modules: [[UInt8]]
    public let dependencies: [SuiAddress]
    public func inner() -> SuiTransactionInner {
        return .Publish(self)
    }
}


public struct SuiUpgradeTransaction: SuiTransactionStruct{
    public let kind: String = "Upgrade"
    public let modules: [[UInt8]]
    public let dependencies: [SuiAddress]
    public let packageId: SuiAddress
    public let ticket: SuiTransactionArgumentType
    public func inner() -> SuiTransactionInner {
        return .Upgrade(self)
    }
}
