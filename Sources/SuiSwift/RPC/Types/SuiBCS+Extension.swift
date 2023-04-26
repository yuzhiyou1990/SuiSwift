//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/18.
//

import Foundation

extension SuiSharedObjectRef: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try objectId.serialize(to: &writer)
        try initialSharedVersion.serialize(to: &writer)
        try mutable.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        objectId = try .init(from: &reader)
        initialSharedVersion = try .init(from: &reader)
        mutable = try .init(from: &reader)
    }
}
extension SuiGasData: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try payment.serialize(to: &writer)
        try owner.serialize(to: &writer)
        try price.serialize(to: &writer)
        try budget.serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        payment = try .init(from: &reader)
        owner = try .init(from: &reader)
        price = try .init(from: &reader)
        budget = try .init(from: &reader)
    }
}
// past
extension SuiObjectArg: BorshCodable{

    public func serialize(to writer: inout Data) throws {
        switch self {
        case .ImmOrOwned(let suiObjectRef):
            try UVarInt(0).serialize(to: &writer)
            try suiObjectRef.serialize(to: &writer)
        case .Shared(let suiSharedObjectRef):
            try UVarInt(1).serialize(to: &writer)
            try suiSharedObjectRef.serialize(to: &writer)
        }
    }

    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self = try .ImmOrOwned(SuiObjectRef(from: &reader))
        case 1:
            self = try .Shared(SuiSharedObjectRef(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("Unknown variant index for SuiObjectArg: \(index)")
        }
    }
}
// past
extension SuiCallArg: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .Pure(let array):
            try UVarInt(0).serialize(to: &writer)
            try array.serialize(to: &writer)
        case .Object(let suiObjectArg):
            try UVarInt(1).serialize(to: &writer)
            try suiObjectArg.serialize(to: &writer)
        case .ObjVec(let array):
            try UVarInt(2).serialize(to: &writer)
            try array.serialize(to: &writer)
        }
    }
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self =  try .Pure(Array(from: &reader))
        case 1:
            self =  try .Object(SuiObjectArg(from: &reader))
        case 2:
            self =  try .ObjVec(Array(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("Unknown variant index for SuiCallArg: \(index)")
        }

    }
}

extension SuiObjectRef: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try objectId.serialize(to: &writer)
        try version.serialize(to: &writer)
        try digest.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        objectId = try .init(from: &reader)
        version = try .init(from: &reader)
        digest = try .init(from: &reader)
    }
}
extension SuiTransactionExpiration: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .None:
            try UVarInt(0).serialize(to: &writer)
        case .Epoch(let uInt64):
            try UVarInt(1).serialize(to: &writer)
            try uInt64.serialize(to: &writer)
        }
    }
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self = .None
        case 1:
            self = .Epoch(try UInt64(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("SuiTransactionExpiration Decoding Error")
        }
    }
}
extension SuiTransactionInner: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .MoveCall(let suiMoveCallTransaction):
            try UVarInt(0).serialize(to: &writer)
            try suiMoveCallTransaction.serialize(to: &writer)
        case .TransferObjects(let suiTransferObjectsTransaction):
            try UVarInt(1).serialize(to: &writer)
            try suiTransferObjectsTransaction.serialize(to: &writer)
        case .SplitCoins(let suiSplitCoinsTransaction):
            try UVarInt(2).serialize(to: &writer)
            try suiSplitCoinsTransaction.serialize(to: &writer)
        case .MergeCoins(let suiMergeCoinsTransaction):
            try UVarInt(3).serialize(to: &writer)
            try suiMergeCoinsTransaction.serialize(to: &writer)
        case .Publish(let suiPublishTransaction):
            try UVarInt(4).serialize(to: &writer)
            try suiPublishTransaction.serialize(to: &writer)
        case .MakeMoveVec(let suiMakeMoveVecTransaction):
            try UVarInt(5).serialize(to: &writer)
            try suiMakeMoveVecTransaction.serialize(to: &writer)
        case .Upgrade(let suiUpgradeTransaction):
            try UVarInt(6).serialize(to: &writer)
            try suiUpgradeTransaction.serialize(to: &writer)
        }
    }
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self = try .MoveCall(SuiMoveCallTransaction.init(from: &reader))
        case 1:
            self = try .TransferObjects(SuiTransferObjectsTransaction.init(from: &reader))
        case 2:
            self = try .SplitCoins(SuiSplitCoinsTransaction.init(from: &reader))
        case 3:
            self = try .MergeCoins(SuiMergeCoinsTransaction.init(from: &reader))
        case 4:
            self = try .Publish(SuiPublishTransaction.init(from: &reader))
        case 5:
            self = try .MakeMoveVec(SuiMakeMoveVecTransaction.init(from: &reader))
        case 6:
            self = try .Upgrade(SuiUpgradeTransaction.init(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("SuiTransactionInner Decoding Error")
        }
    }
}

extension SuiProgrammableTransaction: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try inputs.serialize(to: &writer)
        try transactions.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.inputs = try .init(from: &reader)
        self.transactions = try .init(from: &reader)
    }
}

extension SuiTransactionKind: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .ProgrammableTransaction(let suiProgrammableTransaction):
            try UVarInt(0).serialize(to: &writer)
            try suiProgrammableTransaction.serialize(to: &writer)
        case .ChangeEpoch:
            try UVarInt(1).serialize(to: &writer)
            break
        case .Genesis:
            try UVarInt(2).serialize(to: &writer)
            break
        case .ConsensusCommitPrologue:
            try UVarInt(3).serialize(to: &writer)
            break
        }
    }
    
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self = try .ProgrammableTransaction(SuiProgrammableTransaction(from: &reader))
        case 1:
            self = .ChangeEpoch
        case 2:
            self = .Genesis
        case 3:
            self = .ConsensusCommitPrologue
        default:
            throw SuiError.BCSError.DeserializeError("SuiTransactionKind Decoding Error")
        }
    }
}

extension SuiTransactionDataV1: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try kind.serialize(to: &writer)
        try sender.serialize(to: &writer)
        try gasData.serialize(to: &writer)
        try expiration.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        kind = try .init(from: &reader)
        sender = try .init(from: &reader)
        gasData = try .init(from: &reader)
        expiration = try .init(from: &reader)
    }
}

extension SuiTransactionData: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .V1(let suiTransactionDataV1):
            try UVarInt(0).serialize(to: &writer)
            try suiTransactionDataV1.serialize(to: &writer)
        }
    }
    
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self = .V1(try SuiTransactionDataV1(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("SuiTransactionData Decoding Error")
        }
    }
}
