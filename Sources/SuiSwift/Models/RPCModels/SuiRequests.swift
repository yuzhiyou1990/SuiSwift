//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/3.
//

import Foundation
import UIKit
import BigInt

public struct SuiRequestCoins: Encodable{
    public let owner: SuiAddress
    public let coinType: String?
    public let cursor: SuiObjectId?
    public let limit: UInt64?
    public init(owner: SuiAddress, coinType: String? = SUI_TYPE_ARG, cursor: SuiObjectId? = nil, limit: UInt64? = 100) {
        self.owner = owner
        self.coinType = coinType
        self.cursor = cursor
        self.limit = limit
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.owner.value)
        if coinType != nil {
            try container.encode(self.coinType)
        }
        try container.encode(self.cursor)
        try container.encode(self.limit)
    }
}

public struct SuiRequestBalance: Encodable{
    public let owner: SuiAddress
    public let coinType: String?
    public init(owner: SuiAddress, coinType: String? = SUI_TYPE_ARG) {
        self.owner = owner
        self.coinType = coinType
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.owner.value)
        if coinType != nil {
            try container.encode(self.coinType)
        }
    }
}
public enum SuiObjectDataFilter: Encodable{
    public struct SuiMoveModule: Encodable{
        public let package: SuiObjectId
        public let module: String
        public enum CodingKeys: CodingKey {
            case package
            case module
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.package, forKey: .package)
            try container.encode(self.module, forKey: .module)
        }
    }
    case Package(SuiObjectId)
    case MoveModule(SuiMoveModule)
    case StructType(String)
    public enum CodingKeys: CodingKey {
        case Package
        case MoveModule
        case StructType
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .Package(let package):
            try container.encode(package, forKey: .Package)
        case .MoveModule(let moveModule):
            try container.encode(moveModule, forKey: .MoveModule)
        case .StructType(let type):
            try container.encode(type, forKey: .StructType)
        }
    }
}
public struct SuiObjectResponseQuery: Encodable{
    public let filter: SuiObjectDataFilter?
    public let options: SuiObjectDataOptions?
    public init(filter: SuiObjectDataFilter? = nil, options: SuiObjectDataOptions? = nil) {
        self.filter = filter
        self.options = options
    }
}
public struct SuiObjectDataOptions: Encodable{
    public let showType: Bool?
    public let showContent: Bool?
    public let showBcs: Bool?
    public let showOwner: Bool?
    public let showPreviousTransaction: Bool?
    public let showStorageRebate: Bool?
    public let showDisplay: Bool?
    
    enum CodingKeys: String, CodingKey {
        case showType
        case showContent
        case showBcs
        case showOwner
        case showPreviousTransaction
        case showStorageRebate
        case showDisplay
    }
    public init(showType: Bool? = false, showContent: Bool? = false, showBcs: Bool? = false, showOwner: Bool? = false, showPreviousTransaction: Bool? = false, showStorageRebate: Bool? = false, showDisplay: Bool? = false) {
        self.showType = showType
        self.showContent = showContent
        self.showBcs = showBcs
        self.showOwner = showOwner
        self.showPreviousTransaction = showPreviousTransaction
        self.showStorageRebate = showStorageRebate
        self.showDisplay = showDisplay
    }
    public func encode(to encoder: Encoder) throws {
        var container =  encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showType, forKey: .showType)
        try container.encode(showContent, forKey: .showContent)
        try container.encode(showBcs, forKey: .showBcs)
        try container.encode(showOwner, forKey: .showOwner)
        try container.encode(showPreviousTransaction, forKey: .showPreviousTransaction)
        try container.encode(showStorageRebate, forKey: .showStorageRebate)
        try container.encode(showDisplay, forKey: .showDisplay)
    }
}

extension SuiCheckpointedObjectId: Encodable{
    enum CodingKeys: String, CodingKey {
        case objectId
        case atCheckpoint
    }
    public func encode(to encoder: Encoder) throws {
        var container =  encoder.container(keyedBy: CodingKeys.self)
        try container.encode(objectId, forKey: .objectId)
        try container.encode(atCheckpoint, forKey: .atCheckpoint)
    }
}
public struct SuiPaginationArguments: Encodable{
    public let cursor: SuiCheckpointedObjectId?
    public let limit: UInt64?
    public init(cursor: SuiCheckpointedObjectId?, limit: UInt64?) {
        self.cursor = cursor
        self.limit = limit
    }
}

public struct SuiGetOwnedObjects: Encodable{
    public let owner: SuiAddress
    public let objectResponseQuery: SuiObjectResponseQuery
    public let arguments: SuiPaginationArguments
    public init(owner: SuiAddress, objectResponseQuery: SuiObjectResponseQuery, arguments: SuiPaginationArguments = SuiPaginationArguments(cursor: nil, limit: nil)) {
        self.owner = owner
        self.objectResponseQuery = objectResponseQuery
        self.arguments = arguments
    }
    public enum CodingKeys: CodingKey {
        case owner
        case objectResponseQuery
        case arguments
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.owner.value)
        try container.encode(self.objectResponseQuery)
        try container.encode(self.arguments.cursor)
        try container.encode(self.arguments.limit)
    }
}

public struct SuiGetObject: Encodable{
    public let id: SuiObjectId
    public let option: SuiObjectDataOptions?
    public init(id: SuiObjectId, option: SuiObjectDataOptions? = nil) {
        self.id = id
        self.option = option
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.id)
        try container.encode(self.option)
    }
}

public struct SuiMultiGetObjects: Encodable{
    public let ids: [SuiObjectId]
    public let option: SuiObjectDataOptions?
    public init(ids: [SuiObjectId], option: SuiObjectDataOptions? = nil) {
        self.ids = ids
        self.option = option
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.ids)
        try container.encode(self.option)
    }
}

// Transaction

public struct SuiTransactionBlockResponseOptions: Encodable{
    public let showInput: Bool?
    public let showEffects: Bool?
    public let showEvents: Bool?
    public let showObjectChanges: Bool?
    public let showBalanceChanges: Bool?
    public init(showInput: Bool? = false, showEffects: Bool? = false, showEvents: Bool? = false, showObjectChanges: Bool? = false, showBalanceChanges: Bool? = false) {
        self.showInput = showInput
        self.showEffects = showEffects
        self.showEvents = showEvents
        self.showObjectChanges = showObjectChanges
        self.showBalanceChanges = showBalanceChanges
    }
}
/**
 WaitForEffectsCert: waits for TransactionEffectsCert and then returns to the client. This mode is a proxy for transaction finality.
 WaitForLocalExecution: waits for TransactionEffectsCert and makes sure the node executed the transaction locally before returning to the client. The local execution makes sure this node is aware of this transaction when the client fires subsequent queries. However, if the node fails to execute the transaction locally in a timely manner, a bool type in the response is set to false to indicate the case.
 */
public enum SuiExecuteTransactionRequestType: String, Encodable{
    case WaitForEffectsCert
    case WaitForLocalExecution
}
public typealias SuiSerializedSignature = Base64String
public struct SuiExecuteTransactionBlock: Encodable{
    public let transactionBlock: Base64String
    public let signature: [SuiSerializedSignature]
    public var options: SuiTransactionBlockResponseOptions?
    public var requestType: SuiExecuteTransactionRequestType?
    
    public init(transactionBlock: Base64String, signature: [SuiSerializedSignature], options: SuiTransactionBlockResponseOptions? = SuiTransactionBlockResponseOptions(showInput: true, showEffects: true, showEvents: true), requestType: SuiExecuteTransactionRequestType? = nil) {
        self.transactionBlock = transactionBlock
        self.signature = signature
        self.options = options
        self.requestType = requestType
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(transactionBlock)
        try container.encode(signature)
        try container.encode(options)
        try container.encode(requestType)
    }
}
