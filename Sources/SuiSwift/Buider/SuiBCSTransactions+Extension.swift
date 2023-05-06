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
        case .Genesis:
            try UVarInt(2).serialize(to: &writer)
        case .ConsensusCommitPrologue:
            try UVarInt(3).serialize(to: &writer)
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

// transactions

extension SuiProgrammableCallInner: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try SuiAddress(value: SuiAddress.normalizeSuiAddress(address: package)).serialize(to: &writer)
        try module.serialize(to: &writer)
        try function.serialize(to: &writer)
        if let typeArguments = typeArguments {
            try typeArguments.serialize(to: &writer)
        } else{
            try UVarInt(0).serialize(to: &writer)
        }
        try arguments.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        let package = try SuiAddress.init(from: &reader)
        self.package = package.value
        self.module = try .init(from: &reader)
        self.function = try .init(from: &reader)
        if let typeArguments = try? [SuiTypeTag].init(from: &reader){
            self.typeArguments = typeArguments
        } else{
            self.typeArguments = nil
        }
        self.arguments = try .init(from: &reader)
    }
}

extension SuiMoveCallTransaction: BorshCodable{

    public func serialize(to writer: inout Data) throws {
        let target = self.target.replacingOccurrences(of: " ", with: "")
        let words = target.components(separatedBy: "::")
        guard words.count == 3 else{
            throw SuiError.BCSError.SerializeError("SuiMoveCallTransaction Serialize Error")
        }
        let pkg = words[0]
        var type_arguments: [SuiTypeTag]? = nil
        if typeArguments != nil {
            type_arguments = try typeArguments!.map { tag in
                try SuiTypeTag.parseFromStr(str: tag, normalizeAddress: true)
            }
        }
        let module = words[1]
        let fun = words[2]
        try SuiProgrammableCallInner(package: pkg, module: module, function: fun, typeArguments: type_arguments, arguments: self.arguments).serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        let suiProgrammableCallInner = try SuiProgrammableCallInner.init(from: &reader)
        self.target = suiProgrammableCallInner.package + "::" + suiProgrammableCallInner.module + "::" + suiProgrammableCallInner.function
        let typeArguments = suiProgrammableCallInner.typeArguments?.map({ typeTag in
            return SuiTypeTag.tagToString(tag: typeTag)
        })
        self.typeArguments = typeArguments
        self.arguments = suiProgrammableCallInner.arguments
    }
}

extension SuiTransactionBlockInput: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try index.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.index = try .init(from: &reader)
    }
}

extension SuiResultArgumentType: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try index.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.index = try .init(from: &reader)
    }
}
extension SuiNestedResultArgumentType: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try index.serialize(to: &writer)
        try resultIndex.serialize(to: &writer)
    }
    public init(from reader: inout BinaryReader) throws {
        self.index = try .init(from: &reader)
        self.resultIndex = try .init(from: &reader)
    }
}
extension SuiTransactionArgumentType: BorshCodable{
    
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .GasCoin(_):
            try UVarInt(0).serialize(to: &writer)
        case .TransactionBlockInput(let suiTransactionBlockInput):
            try UVarInt(1).serialize(to: &writer)
            try suiTransactionBlockInput.serialize(to: &writer)
        case .Result(let suiResultArgumentType):
            try UVarInt(2).serialize(to: &writer)
            try suiResultArgumentType.serialize(to: &writer)
        case .NestedResult(let suiNestedResultArgumentType):
            try UVarInt(3).serialize(to: &writer)
            try suiNestedResultArgumentType.serialize(to: &writer)
        }
    }
    
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self = .GasCoin(SuiGasCoinArgumentType())
        case 1:
            self = try .TransactionBlockInput(SuiTransactionBlockInput(from: &reader))
        case 2:
            self = try .Result(SuiResultArgumentType(from: &reader))
        case 3:
            self = try .NestedResult(SuiNestedResultArgumentType(from: &reader))
        default:
            throw SuiError.BCSError.DeserializeError("SuiTransactionArgumentType Decoding Error")
        }
    }
}
extension SuiSplitCoinsTransaction: BorshCodable{
    
    public func serialize(to writer: inout Data) throws {
        try coin.serialize(to: &writer)
        try amounts.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.coin = try .init(from: &reader)
        self.amounts = try .init(from: &reader)
    }
}

extension SuiTransferObjectsTransaction: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try objects.serialize(to: &writer)
        try address.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.objects = try .init(from: &reader)
        self.address = try .init(from: &reader)
    }
}

extension SuiMergeCoinsTransaction: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try destination.serialize(to: &writer)
        try sources.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.destination = try .init(from: &reader)
        self.sources = try .init(from: &reader)
    }
}

extension SuiPublishTransaction: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try modules.serialize(to: &writer)
        try dependencies.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.modules = try .init(from: &reader)
        self.dependencies = try .init(from: &reader)
    }
}

extension SuiMakeMoveVecTransaction: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        if let _type = self.type{
            try _type.serialize(to: &writer)
        }else{
            try UVarInt(0).serialize(to: &writer)
        }
        try objects.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        if let types = try? [SuiTypeTag].init(from: &reader){
            self.type = types
        } else{
            self.type = nil
        }
        self.objects = try .init(from: &reader)
    }
}

extension SuiUpgradeTransaction: BorshCodable{
    
    public func serialize(to writer: inout Data) throws {
        try modules.serialize(to: &writer)
        try dependencies.serialize(to: &writer)
        try packageId.serialize(to: &writer)
        try ticket.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.modules = try .init(from: &reader)
        self.dependencies = try .init(from: &reader)
        self.packageId = try .init(from: &reader)
        self.ticket = try .init(from: &reader)
    }
}
