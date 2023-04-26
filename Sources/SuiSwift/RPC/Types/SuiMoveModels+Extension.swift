//
//  SuiMoveModels+Extension.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation

extension SuiStructType: Equatable{
    public static func == (lhs: SuiStructType, rhs: SuiStructType) -> Bool {
        return lhs.address == rhs.address && lhs.module == rhs.module && lhs.name == rhs.name
    }
    static var RESOLVED_SUI_ID: SuiStructType {
        SuiStructType(address: SUI_FRAMEWORK_ADDRESS, module: OBJECT_MODULE_NAME, name: ID_STRUCT_NAME, typeArguments: [])
    }
    static var RESOLVED_ASCII_STR: SuiStructType {
        SuiStructType(address: MOVE_STDLIB_ADDRESS, module: STD_ASCII_MODULE_NAME, name: STD_ASCII_STRUCT_NAME, typeArguments: [])
    }
    static var RESOLVED_UTF8_STR: SuiStructType {
        SuiStructType(address: MOVE_STDLIB_ADDRESS, module: STD_UTF8_MODULE_NAME, name: STD_UTF8_STRUCT_NAME, typeArguments: [])
    }
    static var RESOLVED_STD_OPTION: SuiStructType {
        SuiStructType(address: MOVE_STDLIB_ADDRESS, module: STD_OPTION_MODULE_NAME, name: STD_OPTION_STRUCT_NAME, typeArguments: [])
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
    public func extractReference() -> SuiMoveNormalizedType?{
        if case .Reference(let suiMoveNormalizedTypeReference) = self {
            return suiMoveNormalizedTypeReference.reference
        }
        return nil
    }
    public func extractMutableReference() -> SuiMoveNormalizedType?{
        if case .MutableReference(let suiMoveNormalizedTypeMutableReference) = self {
            return suiMoveNormalizedTypeMutableReference.mutableReference
        }
        return nil
    }
}
