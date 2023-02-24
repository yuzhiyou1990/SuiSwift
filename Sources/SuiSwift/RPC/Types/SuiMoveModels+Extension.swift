//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/5.
//

import Foundation

let STD_ASCII_MODULE_NAME = "ascii"
let STD_ASCII_STRUCT_NAME = "String"

let STD_UTF8_MODULE_NAME = STD_ASCII_STRUCT_NAME.lowercased()
let STD_UTF8_STRUCT_NAME = STD_ASCII_STRUCT_NAME

let STD_OPTION_MODULE_NAME = "option"
let STD_OPTION_STRUCT_NAME = "option"

extension SuiStructType: Equatable{
    public static func == (lhs: SuiStructType, rhs: SuiStructType) -> Bool {
        return lhs.address == rhs.address && lhs.module == rhs.module && lhs.name == rhs.name
    }
    static var RESOLVED_SUI_ID: SuiStructType {
        SuiStructType(address: SUI_FRAMEWORK_ADDRESS, module: OBJECT_MODULE_NAME, name: ID_STRUCT_NAME, type_arguments: [])
    }
    static var RESOLVED_ASCII_STR: SuiStructType {
        SuiStructType(address: MOVE_STDLIB_ADDRESS, module: STD_ASCII_MODULE_NAME, name: STD_ASCII_STRUCT_NAME, type_arguments: [])
    }
    static var RESOLVED_UTF8_STR: SuiStructType {
        SuiStructType(address: MOVE_STDLIB_ADDRESS, module: STD_UTF8_MODULE_NAME, name: STD_UTF8_STRUCT_NAME, type_arguments: [])
    }
    static var RESOLVED_STD_OPTION: SuiStructType {
        SuiStructType(address: MOVE_STDLIB_ADDRESS, module: STD_OPTION_MODULE_NAME, name: STD_OPTION_STRUCT_NAME, type_arguments: [])
    }
}
extension SuiTypeArgument: BorshSerializable{
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .Utf8string(let string):
            try string?.serialize(to: &writer)
        case .String(let string):
            try string?.serialize(to: &writer)
        case .TypeTag(let suiTypeTag, let suiJsonValue):
            guard let value = suiJsonValue else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize TypeTag Error: \(suiTypeTag), Value is Null")
            }
            try value.encode(type: suiTypeTag, to: &writer)
        case .Address(let string):
            guard let address = string else{
                throw SuiError.DataSerializerError.ParseError("\(SuiCallArgSerializer.MOVE_CALL_SER_ERROR) Serialize Address Error")
            }
            try SuiAddress(value: address).serialize(to: &writer)
        case .Vector(let typeArgument):
            try typeArgument?.serialize(to: &writer)
        }
    }
}
// move call

extension SuiMoveFunctionArgType{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .Str(str)
            return
        }
        if let argTypeObject = try? container.decode(ArgTypeObject.self) {
            self = .Object(argTypeObject)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiMoveFunctionArgType Decoder Error")
    }
}

extension SuiMoveNormalizedType{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .Str(str)
            return
        }
        if let parameterType = try? container.decode(SuiMoveNormalizedTypeParameterType.self) {
            self = .MoveNormalizedTypeParameterType(parameterType)
            return
        }
        if let moveNormalizedTypeReference_Reference = try? container.decode(SuiMoveNormalizedTypeReference.self) {
            self = .Reference(moveNormalizedTypeReference_Reference)
            return
        }
        if let moveNormalizedTypeReference_MutableReference = try? container.decode(SuiMoveNormalizedTypeMutableReference.self) {
            self = .MutableReference(moveNormalizedTypeReference_MutableReference)
            return
        }
        if let vector = try? container.decode(SuiMoveNormalizedTypeVector.self) {
            self = .Vector(vector)
            return
        }
        if let structType = try? container.decode(SuiMoveNormalizedStructType.self) {
            self = .MoveNormalizedStructType(structType)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiMoveNormalizedType Decoder Error")
    }
    
    public func extractStructTag() -> SuiMoveNormalizedStructType?{
        switch self {
        case .Str(_): return nil
        case .MoveNormalizedTypeParameterType(_):  return nil
        case .Reference(let suiMoveNormalizedTypeReference):
            return suiMoveNormalizedTypeReference.reference.extractStructTag()
        case .MutableReference(let suiMoveNormalizedTypeMutableReference):
            return suiMoveNormalizedTypeMutableReference.mutableReference.extractStructTag()
        case .Vector(_):  return nil
        case .MoveNormalizedStructType(let suiMoveNormalizedStructType):
            return suiMoveNormalizedStructType
        }
    }
}
