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

// transaction
public struct SuiGasCoinArgumentType{
    public static let kind: String = "GasCoin"
    public init(){}
}
public struct SuiTransactionBlockInput{
    public static let kind: String = "Input"
    public var index: UInt16
    public var value: SuiJsonValue?
    public var type: String?
    public init(kind: String = "Input", index: UInt16, value: SuiJsonValue? = nil, type: String? = nil) {
        self.index = index
        self.value = value
        self.type = type
    }
}
public struct SuiResultArgumentType{
    public static let kind: String = "Result"
    public let index: UInt16
    public init(index: UInt16) {
        self.index = index
    }
}
public struct SuiNestedResultArgumentType{
    public static let kind: String = "NestedResult"
    public let index: UInt16
    public let resultIndex: UInt16
    public init(index: UInt16, resultIndex: UInt16) {
        self.index = index
        self.resultIndex = resultIndex
    }
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
public struct SuiProgrammableCallInner{
    public let package: String
    public let module: String
    public let function: String
    public var typeArguments: [SuiTypeTag]?
    public var arguments: [SuiTransactionArgumentType]
    public init(package: String, module: String, function: String, typeArguments: [SuiTypeTag]? = nil, arguments: [SuiTransactionArgumentType]) {
        self.package = package
        self.module = module
        self.function = function
        self.typeArguments = typeArguments
        self.arguments = arguments
    }
}

// encode inputs
extension SuiMoveCallTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws {
       try self.arguments.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
    }
}

extension SuiTransferObjectsTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws {
        try self.objects.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
        if case .TransactionBlockInput(let blockInput) =  self.address {
            try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
        }
    }
}

extension SuiSplitCoinsTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws {
        if case .TransactionBlockInput(let blockInput) =  self.coin {
            try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
        }
        try self.amounts.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
    }
}
extension SuiMergeCoinsTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws {
        if case .TransactionBlockInput(let blockInput) =  self.destination {
            try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
        }
        try self.sources.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
    }
}
extension SuiMakeMoveVecTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws{
        try self.objects.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
    }
}

extension SuiPublishTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws{
        debugPrint("kind !== 'Input'")
    }
}

extension SuiUpgradeTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws{
        if case .TransactionBlockInput(let blockInput) =  self.ticket {
            try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
        }
    }
}

extension SuiTransactionInner{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws{
        switch self {
        case .MoveCall(let suiMoveCallTransaction):
            try suiMoveCallTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .TransferObjects(let suiTransferObjectsTransaction):
            try suiTransferObjectsTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .SplitCoins(let suiSplitCoinsTransaction):
            try suiSplitCoinsTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .MergeCoins(let suiMergeCoinsTransaction):
            try suiMergeCoinsTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .Publish(let suiPublishTransaction):
            try suiPublishTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .MakeMoveVec(let suiMakeMoveVecTransaction):
            try suiMakeMoveVecTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .Upgrade(let suiUpgradeTransaction):
            try suiUpgradeTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        }
    }
}
