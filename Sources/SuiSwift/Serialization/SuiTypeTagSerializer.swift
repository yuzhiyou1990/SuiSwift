//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/11.
//

import Foundation

public let SUI_VECTOR_REGEX = "^vector<(.+)>$"
public let SUI_STRUCT_REGEX = "^([^:]+)::([^:]+)::(.+)"
public let SUI_STRUCT_TYPE_TAG_REGEX = "^[^<]+<(.+)>$"
public let SUI_STRUCT_NAME_REGEX = "^([^<]+)"
/**
 * Kind of a TypeTag which is represented by a Move type identifier.
 */
public struct SuiStructTag{
    public var address: SuiAddress
    public var module: String
    public var name: String
    public var typeParams: [SuiTypeTag]
    public init(address: SuiAddress, module: String, name: String, typeParams: [SuiTypeTag]) {
        self.address = address
        self.module = module
        self.name = name
        self.typeParams = typeParams
    }
}

extension SuiStructTag: BorshCodable{
    
    public func serialize(to writer: inout Data) throws {
        try address.serialize(to: &writer)
        try module.serialize(to: &writer)
        try name.serialize(to: &writer)
        try typeParams.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        address = try SuiAddress(from: &reader)
        module = try String(from: &reader)
        name = try String(from: &reader)
        typeParams = try [SuiTypeTag](from: &reader)
    }
}
/**
 * Sui TypeTag object. A decoupled `0x...::module::Type<???>` parameter.
 */
public indirect enum SuiTypeTag{
    case Bool
    case UInt8
    case UInt64
    case UInt128
    case Address
    case Signer
    case Vector(SuiTypeTag)
    case Struct(SuiStructTag)
    case UInt16
    case UInt32
    case UInt256
}
extension SuiTypeTag: BorshCodable{
    
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .Bool:
            try UVarInt(0).serialize(to: &writer)
        case .UInt8:
            try UVarInt(1).serialize(to: &writer)
        case .UInt64:
            try UVarInt(2).serialize(to: &writer)
        case .UInt128:
            try UVarInt(3).serialize(to: &writer)
        case .Address:
            try UVarInt(4).serialize(to: &writer)
        case .Signer:
            try UVarInt(5).serialize(to: &writer)
        case .Vector(let suiTypeTag):
            try UVarInt(6).serialize(to: &writer)
            try suiTypeTag.serialize(to: &writer)
        case .Struct(let suiStructTag):
            try UVarInt(7).serialize(to: &writer)
            try suiStructTag.serialize(to: &writer)
        case .UInt16:
            try UVarInt(8).serialize(to: &writer)
        case .UInt32:
            try UVarInt(9).serialize(to: &writer)
        case .UInt256:
            try UVarInt(10).serialize(to: &writer)
        }
    }
    
    public init(from reader: inout BinaryReader) throws {
        let index = try UVarInt.init(from: &reader).value
        switch index {
        case 0:
            self = .Bool
        case 1:
            self = .UInt8
        case 2:
            self = .UInt64
        case 3:
            self = .UInt128
        case 4:
            self = .Address
        case 5:
            self = .Signer
        case 6:
            self = .Vector(try SuiTypeTag(from: &reader))
        case 7:
            self = .Struct(try SuiStructTag(from: &reader))
        case 8:
            self = .UInt16
        case 9:
            self = .UInt32
        case 10:
            self = .UInt256
        default:
            throw SuiError.BCSError.DeserializeError("Unknown variant index for SuiTypeTag: \(index)")
        }
    }
}
extension SuiTypeTag{
    public static func parseBase(str: String) -> SuiTypeTag?{
        if str == "address" {
            return .Address
        } else if str == "bool" {
            return .Bool
        } else if str == "u8" {
            return .UInt8
        } else if str == "u16" {
            return .UInt16
        } else if str == "u32" {
            return .UInt32
        } else if str == "u64" {
            return .UInt64
        } else if str == "u128" {
            return .UInt128
        } else if str == "u256" {
            return .UInt256
        } else if str == "signer" {
            return .Signer
        }
        return nil
    }
    public static func parseFromStr(str: String) throws -> SuiTypeTag{
        let baseType = parseBase(str: str)
        if baseType != nil{
            return baseType!
        }
        let vectorRangeIndexs = str.match(pattern: SUI_VECTOR_REGEX)
        let vectorMatch: [String] = vectorRangeIndexs.map { String(str[$0]) }
        if vectorMatch.count >= 2{
            return try .Vector(parseFromStr(str: vectorMatch[1]))
        }
        let structRangeIndexs = str.match(pattern: SUI_STRUCT_REGEX)
        let structMatch: [String] = structRangeIndexs.map { String(str[$0]) }
        if structMatch.count >= 4{
            let nameRangeIndexs = structMatch[3].match(pattern: SUI_STRUCT_NAME_REGEX)
            let nameMatch: [String] = nameRangeIndexs.map { String(structMatch[3][$0]) }
            
            return .Struct(SuiStructTag(address: try SuiAddress(value: structMatch[1].addHexPrefix()), module: structMatch[2], name: nameMatch[1], typeParams: try parseStructTypeTag(str: structMatch[3])))
        }
        throw SuiError.DataSerializerError.ParseError("Encounter unexpected token when parsing type args for \(str)")
    }
    public static func parseStructTypeTag(str: String) throws -> [SuiTypeTag]{
        let ranges = str.match(pattern: SUI_STRUCT_TYPE_TAG_REGEX)
        guard ranges.count > 0 else{
            return []
        }
        let found: [String] = ranges.map { String(str[$0]) }
        
        // TODO: This will fail if the struct has nested type args with commas. Need
        // to implement proper parsing for this case
        let typeTags = found[1].components(separatedBy: ",")
        return try typeTags.map{try parseFromStr(str: $0)}
    }
}
