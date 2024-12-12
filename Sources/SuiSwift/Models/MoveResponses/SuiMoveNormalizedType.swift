//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

public indirect enum SuiMoveNormalizedType: Decodable{
    case Str(String)
    case MoveNormalizedTypeParameterType(SuiMoveNormalizedTypeParameterType)
    case Reference(SuiMoveNormalizedTypeReference)
    case MutableReference(SuiMoveNormalizedTypeMutableReference)
    case Vector(SuiMoveNormalizedTypeVector)
    case MoveNormalizedStructType(SuiMoveNormalizedStructType)
}

extension SuiMoveNormalizedType{
    public static func isTxContext(param: SuiMoveNormalizedType) -> Bool{
        let structType = param.extractStructTag()?.structType
        guard structType?.address == "0x2",
              structType?.module == "tx_context",
              structType?.name == "TxContext" else{
            return false
        }
        return true
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
