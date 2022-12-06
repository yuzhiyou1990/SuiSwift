//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/15.
//

import Foundation

extension SuiSharedObjectRef: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try objectId.serialize(to: &writer)
        try initialSharedVersion.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        objectId = try .init(from: &reader)
        initialSharedVersion = try .init(from: &reader)
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

extension SuiObjectArg: BorshCodable{
    
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .ImmOrOwned(let suiObjectRef):
            try UVarInt(0).serialize(to: &writer)
            try suiObjectRef.serialize(to: &writer)
        case .Shared(let suiSharedObjectRef):
            try UVarInt(1).serialize(to: &writer)
            try suiSharedObjectRef.serialize(to: &writer)
        case .Shared_Deprecated(let string):
            try UVarInt(2).serialize(to: &writer)
            try string.serialize(to: &writer)
        }
    }
    
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self = try .ImmOrOwned(SuiObjectRef(from: &reader))
        case 1:
            self = try .Shared(SuiSharedObjectRef(from: &reader))
        case 2:
            self = try .Shared_Deprecated(String(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("Unknown variant index for SuiObjectArg: \(index)")
        }
    }
}

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

extension SuiTransferObjectTx: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try recipient.serialize(to: &writer)
        try object_ref.serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        recipient = try .init(from: &reader)
        object_ref = try .init(from: &reader)
    }
}
extension SuiPublishTx: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try modules.serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        modules = try Array(from: &reader)
    }
}
extension SuiMoveCallTx: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try package.serialize(to: &writer)
        try module.serialize(to: &writer)
        try function.serialize(to: &writer)
        try typeArguments.serialize(to: &writer)
        try arguments.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        package = try .init(from: &reader)
        module = try .init(from: &reader)
        function = try .init(from: &reader)
        typeArguments = try .init(from: &reader)
        arguments = try .init(from: &reader)
    }
}

extension SuiTransferSuiTx: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try recipient.serialize(to: &writer)
        if amount == .none {
            try UVarInt(0).serialize(to: &writer)
        }
        else {
            try UVarInt(1).serialize(to: &writer)
            try amount.unsafelyUnwrapped.serialize(to: &writer)
        }
    }
    public init(from reader: inout BinaryReader) throws {
        recipient = try .init(from: &reader)
        let index = try UVarInt.init(from: &reader).value
        switch index{
        case 0:
            amount = .none
        case 1:
            amount = .some(try .init(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("Unknown variant index for SuiTransferSuiTx.Amount: \(index)")
        }
    }
}

extension SuiPayTx: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try coins.serialize(to: &writer)
        try recipients.serialize(to: &writer)
        try amounts.serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        coins = try .init(from: &reader)
        recipients = try .init(from: &reader)
        amounts = try .init(from: &reader)
    }
}

extension SuiPaySuiTx: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try coins.serialize(to: &writer)
        try recipients.serialize(to: &writer)
        try amounts.serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        coins = try .init(from: &reader)
        recipients = try .init(from: &reader)
        amounts = try .init(from: &reader)
    }
}

extension SuiPayAllSuiTx: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try coins.serialize(to: &writer)
        try recipient.serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        coins = try .init(from: &reader)
        recipient = try .init(from: &reader)
    }
}

extension SuiTransaction: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .TransferObjectTx(let suiTransferObjectTx):
            try UVarInt(0).serialize(to: &writer)
            try suiTransferObjectTx.serialize(to: &writer)
        case .PublishTx(let suiPublishTx):
            try UVarInt(1).serialize(to: &writer)
            try suiPublishTx.serialize(to: &writer)
        case .MoveCallTx(let suiMoveCallTx):
            try UVarInt(2).serialize(to: &writer)
            try suiMoveCallTx.serialize(to: &writer)
        case .TransferSuiTx(let suiTransferSuiTx):
            try UVarInt(3).serialize(to: &writer)
            try suiTransferSuiTx.serialize(to: &writer)
        case .PayTx(let suiPayTx):
            try UVarInt(4).serialize(to: &writer)
            try suiPayTx.serialize(to: &writer)
        case .PaySuiTx(let suiPaySuiTx):
            try UVarInt(5).serialize(to: &writer)
            try suiPaySuiTx.serialize(to: &writer)
        case .PayAllSuiTx(let suiPayAllSuiTx):
            try UVarInt(6).serialize(to: &writer)
            try suiPayAllSuiTx.serialize(to: &writer)
        }
    }
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index{
        case 0:
            self = .TransferObjectTx(try SuiTransferObjectTx(from: &reader))
        case 1:
            self = .PublishTx(try SuiPublishTx(from: &reader))
        case 2:
            self = .MoveCallTx(try SuiMoveCallTx(from: &reader))
        case 3:
            self = .TransferSuiTx(try SuiTransferSuiTx(from: &reader))
        case 4:
            self = .PayTx(try SuiPayTx(from: &reader))
        case 5:
            self = .PaySuiTx(try SuiPaySuiTx(from: &reader))
        case 6:
            self = .PayAllSuiTx(try SuiPayAllSuiTx(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("Unknown variant index for SuiTransaction: \(index)")
        }
    }
}
extension SuiTransactionKind: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .Single(let suiTransaction):
            try UVarInt(0).serialize(to: &writer)
            try suiTransaction.serialize(to: &writer)
        case .Batch(let array):
            try UVarInt(1).serialize(to: &writer)
            try array.serialize(to: &writer)
        }
    }
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index{
        case 0:
            self = .Single(try SuiTransaction(from: &reader))
        case 1:
            self = .Batch(try [SuiTransaction](from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("Unknown variant index for SuiTransactionKind: \(index)")
        }
    }
}

extension SuiTransactionData: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        writer.append(typeTag.data(using: .utf8)!)
        try kind.serialize(to: &writer)
        try sender.serialize(to: &writer)
        try gasPayment.serialize(to: &writer)
        try gasPrice.serialize(to: &writer)
        try gasBudget.serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        let _ = reader.read(count: UInt32(typeTag.data(using: .utf8)!.count))
        kind = try .init(from: &reader)
        sender = try .init(from: &reader)
        gasPayment = try .init(from: &reader)
        gasPrice = try .init(from: &reader)
        gasBudget = try .init(from: &reader)
    }
}
