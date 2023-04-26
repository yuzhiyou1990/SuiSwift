//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/19.
//

import Foundation

extension SuiProgrammableCallInner: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try SuiAddress(value: package).serialize(to: &writer)
        try module.serialize(to: &writer)
        try function.serialize(to: &writer)
        if let typeArguments = typeArguments {
            try typeArguments.serialize(to: &writer)
        }else{
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
        let words = self.target.components(separatedBy: "::")
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
