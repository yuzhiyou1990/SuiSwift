//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
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
    public static func parseFromStr(str: String, normalizeAddress: Bool = false) throws -> SuiTypeTag{
        let baseType = parseBase(str: str)
        if baseType != nil{
            return baseType!
        }
        let vectorRangeIndexs = str.match(pattern: SUI_VECTOR_REGEX)
        let vectorMatch: [String] = vectorRangeIndexs.map { String(str[$0]) }
        if vectorMatch.count >= 2{
            return try .Vector(parseFromStr(str: vectorMatch[1], normalizeAddress: normalizeAddress))
        }
        let structRangeIndexs = str.match(pattern: SUI_STRUCT_REGEX)
        let structMatch: [String] = structRangeIndexs.map { String(str[$0]) }
        if structMatch.count >= 4{
            // address
            let address = normalizeAddress ? SuiAddress.normalizeSuiAddress(address: structMatch[1]) : structMatch[1]
            let typeParams = structMatch.count == 6 ? try parseStructTypeTag(str: structMatch[5], normalizeAddress: normalizeAddress) : nil
            return .Struct(SuiStructTag(address: try SuiAddress(value: address), module: structMatch[2], name: structMatch[3], typeParams: typeParams))
        }
        throw SuiError.DataSerializerError.ParseError("Encounter unexpected token when parsing type args for \(str)")
    }
    
    public static func parseStructTypeTag(str: String, normalizeAddress: Bool = false) throws -> [SuiTypeTag]{
        var tok = [String]()
        var word = ""
        var nestedAngleBrackets = 0
        for char in str{
            if char == "<"{
                nestedAngleBrackets += 1
            }
            if char == ">"{
                nestedAngleBrackets -= 1
            }
            if nestedAngleBrackets == 0 && char == ","{
                tok.append(word.trimmingCharacters(in: .whitespacesAndNewlines))
                word = ""
                continue
            }
            word = word + String(char)
        }
        tok.append(word.trimmingCharacters(in: .whitespacesAndNewlines))
        
        let result = try tok.map { tok in
            try parseFromStr(str: tok, normalizeAddress: normalizeAddress)
        }
        return result
    }
    
    public static func tagToString(tag: SuiTypeTag) -> String{
        switch tag{
        case .Bool:
            return "bool"
        case .UInt8:
            return "u8"
        case .UInt16:
            return "u16"
        case .UInt32:
            return "u32"
        case .UInt64:
            return "u64"
        case .UInt128:
            return "u128"
        case .UInt256:
            return "u256"
        case .Address:
            return "address"
        case .Signer:
            return "signer"
        case .Vector(let typeTag):
            return "vector<\(tagToString(tag: typeTag))>"
        case .Struct(let structTag):
            var typeParams = ""
            let suffixToRemove = ", "
            structTag.typeParams?.forEach({ typeTag in
                typeParams = typeParams + SuiTypeTag.tagToString(tag: typeTag) + suffixToRemove
            })
            if typeParams.hasSuffix(suffixToRemove) {
                let newEndIndex = typeParams.index(typeParams.endIndex, offsetBy: -suffixToRemove.count)
                typeParams = String(typeParams[..<newEndIndex])
            }
            return "\(structTag.address.value)::\(structTag.module)::\(structTag.name)\(structTag.typeParams != nil ? "<\(typeParams)>" : "")"
        }
    }
}

