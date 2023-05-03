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

extension SuiTransactionInner{
    public static func transactionType(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let kind = dic["kind"] as? String else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid kind")
        }
        guard let transaction = SuiTransactionInner.transactionType()[kind] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid Transaction Type")
        }
        return try transaction.getTransaction(dic: dic)
    }
    public static func transactionType() -> [String: SuiTransactionStruct.Type]{
        return [SuiMoveCallTransaction.kind: SuiMoveCallTransaction.self,
                SuiTransferObjectsTransaction.kind: SuiTransferObjectsTransaction.self,
                SuiSplitCoinsTransaction.kind: SuiSplitCoinsTransaction.self,
                SuiMergeCoinsTransaction.kind: SuiMergeCoinsTransaction.self,
                SuiMakeMoveVecTransaction.kind: SuiMakeMoveVecTransaction.self,
                SuiPublishTransaction.kind: SuiPublishTransaction.self,
                SuiUpgradeTransaction.kind: SuiUpgradeTransaction.self]
    }
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
    public static func input(dic: [String: Any]) throws -> SuiTransactionBlockInput{
        guard let index = dic["index"] as? UInt,
              let type = dic["type"] as? String else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SuiTransactionBlockInput ArgumentType")
        }
        if type == "object"{
            guard let objectid = dic["value"] as? String else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SuiTransactionBlockInput Object")
            }
            return SuiTransactionBlockInput(index: UInt16(index), value: .Str(objectid), type: type)
        }
        if type == "pure" {
            if let value = dic["value"] as? String {
                return SuiTransactionBlockInput(index: UInt16(index), value: .Str(value), type: type)
            }
            if let value = dic["value"] as? UInt64 {
                return SuiTransactionBlockInput(index: UInt16(index), value: .Str("\(value)"), type: type)
            }
        }
        throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SuiTransactionBlockInput")
    }
}
public struct SuiResultArgumentType{
    public static let kind: String = "Result"
    public let index: UInt16
}
public struct SuiNestedResultArgumentType{
    public static let kind: String = "NestedResult"
    public let index: UInt16
    public let resultIndex: UInt16
}

public enum SuiTransactionArgumentType{
    case GasCoin(SuiGasCoinArgumentType)
    case TransactionBlockInput(SuiTransactionBlockInput)
    case Result(SuiResultArgumentType)
    case NestedResult(SuiNestedResultArgumentType)
}

extension SuiTransactionArgumentType{
    public static func type(dic: [String: Any]) throws -> SuiTransactionArgumentType{
        guard let kind = dic["kind"] as? String else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid ArgumentType")
        }
        switch kind{
        case SuiGasCoinArgumentType.kind:
            return .GasCoin(SuiGasCoinArgumentType())
        case SuiResultArgumentType.kind:
            guard let index = dic["index"] as? UInt else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid ArgumentType")
            }
            return .Result(SuiResultArgumentType(index: UInt16(exactly: index)!))
        case SuiNestedResultArgumentType.kind:
            guard let index = dic["index"] as? UInt,
                  let resultIndex = dic["resultIndex"] as? UInt else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid ArgumentType")
            }
            return .NestedResult(SuiNestedResultArgumentType(index: UInt16(exactly: index)!, resultIndex: UInt16(exactly: resultIndex)!))
        default:
            return .TransactionBlockInput(try SuiTransactionBlockInput.input(dic: dic))
        }
    }
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
    static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner
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

public struct SuiMoveCallTransaction: SuiTransactionStruct{
    public static let kind: String = "MoveCall"
    public var target: String = ""
    public var typeArguments: [String]?
    public var arguments: [SuiTransactionArgumentType]
    public init(target: String, typeArguments: [String]? = nil, arguments: [SuiTransactionArgumentType]) {
        self.target = target
        self.typeArguments = typeArguments
        self.arguments = arguments
    }
    public func inner() -> SuiTransactionInner {
        return .MoveCall(self)
    }
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let target = dic["target"] as? String,
              let argumentDics = dic["arguments"] as? [[String: Any]] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid Target")
        }
        let arguments = try argumentDics.map { dic in
            return try SuiTransactionArgumentType.type(dic: dic)
        }
        let typeArguments = dic["typeArguments"] as? [String]
        let transaction = SuiMoveCallTransaction(target: target, typeArguments: typeArguments, arguments: arguments)
        return .MoveCall(transaction)
    }
}

public struct SuiTransferObjectsTransaction: SuiTransactionStruct{
    public static let kind: String = "TransferObjects"
    public let objects: [SuiTransactionArgumentType]
    public let address: SuiTransactionArgumentType
    public init(objects: [SuiTransactionArgumentType], address: SuiTransactionArgumentType) {
        self.objects = objects
        self.address = address
    }
    public func inner() -> SuiTransactionInner {
        return .TransferObjects(self)
    }
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let objectsDics = dic["objects"] as? [[String: Any]],
              let addressDic = dic["address"] as? [String: Any] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid objects")
        }
        let objects = try objectsDics.map { dic in
            return try SuiTransactionArgumentType.type(dic: dic)
        }
        let address = try SuiTransactionArgumentType.type(dic: addressDic)
        let transaction = SuiTransferObjectsTransaction(objects: objects, address: address)
        return .TransferObjects(transaction)
    }
}

public struct SuiSplitCoinsTransaction: SuiTransactionStruct{
    public static let kind: String = "SplitCoins"
    public let coin: SuiTransactionArgumentType
    public let amounts: [SuiTransactionArgumentType]
    public init(coin: SuiTransactionArgumentType, amounts: [SuiTransactionArgumentType]) {
        self.coin = coin
        self.amounts = amounts
    }
    public func inner() -> SuiTransactionInner {
        return .SplitCoins(self)
    }
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let amountsDics = dic["amounts"] as? [[String: Any]],
              let coinDic = dic["coin"] as? [String: Any] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SplitCoins Type")
        }
        let amounts = try amountsDics.map { dic in
            return try SuiTransactionArgumentType.type(dic: dic)
        }
        let coin = try SuiTransactionArgumentType.type(dic: coinDic)
        let transaction = SuiSplitCoinsTransaction(coin: coin, amounts: amounts)
        return .SplitCoins(transaction)
    }
}

public struct SuiMergeCoinsTransaction: SuiTransactionStruct{
    public static let kind: String = "MergeCoins"
    public let destination: SuiTransactionArgumentType
    public let sources: [SuiTransactionArgumentType]
    public init(destination: SuiTransactionArgumentType, sources: [SuiTransactionArgumentType]) {
        self.destination = destination
        self.sources = sources
    }
    public func inner() -> SuiTransactionInner {
        return .MergeCoins(self)
    }
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let sourcesDics = dic["sources"] as? [[String: Any]],
              let destinationDic = dic["destination"] as? [String: Any] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid MergeCoins Type")
        }
        let sources = try sourcesDics.map { dic in
            return try SuiTransactionArgumentType.type(dic: dic)
        }
        let destination = try SuiTransactionArgumentType.type(dic: destinationDic)
        let transaction = SuiMergeCoinsTransaction(destination: destination, sources: sources)
        return .MergeCoins(transaction)
    }
}

public struct SuiMakeMoveVecTransaction: SuiTransactionStruct{
    public static let kind: String = "MakeMoveVec"
    public let type: [SuiTypeTag]?
    public let objects: [SuiTransactionArgumentType]
    public init(type: [SuiTypeTag]?, objects: [SuiTransactionArgumentType]) {
        self.type = type
        self.objects = objects
    }
    public func inner() -> SuiTransactionInner {
        return .MakeMoveVec(self)
    }
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let objectsDics = dic["objects"] as? [[String: Any]]  else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid MakeMove Type")
        }
        let objects = try objectsDics.map { dic in
            return try SuiTransactionArgumentType.type(dic: dic)
        }
        return .MakeMoveVec(.init(type: nil, objects: objects))
    }
}

public struct SuiPublishTransaction: SuiTransactionStruct{
    public static let kind: String = "Publish"
    public let modules: [[UInt8]]
    public let dependencies: [SuiAddress]
    public init(modules: [[UInt8]], dependencies: [SuiAddress]) {
        self.modules = modules
        self.dependencies = dependencies
    }
    public func inner() -> SuiTransactionInner {
        return .Publish(self)
    }
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        return .Publish(.init(modules: [], dependencies: []))
    }
}

public struct SuiUpgradeTransaction: SuiTransactionStruct{
    public static let kind: String = "Upgrade"
    public let modules: [[UInt8]]
    public let dependencies: [SuiAddress]
    public let packageId: SuiAddress
    public let ticket: SuiTransactionArgumentType
    public init(modules: [[UInt8]], dependencies: [SuiAddress], packageId: SuiAddress, ticket: SuiTransactionArgumentType) {
        self.modules = modules
        self.dependencies = dependencies
        self.packageId = packageId
        self.ticket = ticket
    }
    public func inner() -> SuiTransactionInner {
        return .Upgrade(self)
    }
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        return .Upgrade(.init(modules: [], dependencies: [], packageId: try SuiAddress(value: ""), ticket: .GasCoin(.init())))
    }
}
