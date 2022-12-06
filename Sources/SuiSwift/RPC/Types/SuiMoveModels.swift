//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/5.
//

import Foundation
// move call

public indirect enum SuiTypeArgument{
    case Utf8string(String?)
    case String(String?)
    case TypeTag(SuiTypeTag, SuiJsonValue?)
    case Address(String?)
    case Vector(SuiTypeArgument?)
}
public enum SuiMoveFunctionArgType: Decodable{
    public struct ArgTypeObject: Decodable{
        public var object: String
        enum CodingKeys: String, CodingKey {
            case object = "Object"
        }
    }
    case Str(String)
    case Object(ArgTypeObject)
}

public typealias SuiMoveFunctionArgTypes = [SuiMoveFunctionArgType]
public typealias SuiMoveNormalizedModules = [String: SuiMoveNormalizedModule]

public struct SuiMoveNormalizedModule: Decodable{
    public var file_format_version: Int
    public var address: String
    public var name: String
    public var friends: [SuiMoveModuleId]
    public var structs: [String: SuiMoveNormalizedStruct]
    public var exposed_functions: [String: SuiMoveNormalizedFunction]?
}
public struct SuiMoveAbilitySet: Decodable{
    public var abilities: [String]
}
public struct SuiMoveNormalizedStruct: Decodable{
    public var abilities: SuiMoveAbilitySet
    public var type_parameters: [SuiMoveStructTypeParameter]
    public var fields: [SuiMoveNormalizedField]
}

public struct SuiMoveStructTypeParameter: Decodable{
    public var constraints: SuiMoveAbilitySet
    public var is_phantom: Bool
}

public struct SuiMoveNormalizedField: Decodable{
    public var name: String
    public var type_: SuiMoveNormalizedType
}
public struct SuiMoveModuleId: Decodable{
    public var address: String
    public var name: String
}
public typealias SuiMoveTypeParameterIndex = UInt64
public struct SuiMoveNormalizedTypeParameterType: Decodable{
    public var typeParameter: SuiMoveTypeParameterIndex
    enum CodingKeys: String, CodingKey {
        case typeParameter = "TypeParameter"
    }
}
public struct SuiStructType: Decodable{
    public var address: String
    public var module: String
    public var name: String
    public var type_arguments: [SuiMoveNormalizedType]
}

public struct SuiMoveNormalizedStructType: Decodable{
    public var structType: SuiStructType
    enum CodingKeys: String, CodingKey {
        case structType = "Struct"
    }
}

public struct SuiMoveNormalizedTypeReference: Decodable{
    public var reference: SuiMoveNormalizedType
    enum CodingKeys: String, CodingKey {
        case reference = "Reference"
    }
}
public struct SuiMoveNormalizedTypeMutableReference: Decodable{
    public var mutableReference: SuiMoveNormalizedType
    enum CodingKeys: String, CodingKey {
        case mutableReference = "MutableReference"
    }
}
public struct SuiMoveNormalizedTypeVector: Decodable{
    public var vector: SuiMoveNormalizedType
    enum CodingKeys: String, CodingKey {
        case vector = "Vector"
    }
}
public struct SuiMoveNormalizedFunction: Decodable{
    public var visibility: SuiMoveVisibility
    public var is_entry: Bool
    public var type_parameters: [SuiMoveAbilitySet]
    public var parameters: [SuiMoveNormalizedType]
    public var return_: [SuiMoveNormalizedType]
}
public enum SuiMoveVisibility: String, Decodable{
    case Private
    case Public
    case Friend
}

public indirect enum SuiMoveNormalizedType: Decodable{
    case Str(String)
    case MoveNormalizedTypeParameterType(SuiMoveNormalizedTypeParameterType)
    case Reference(SuiMoveNormalizedTypeReference)
    case MutableReference(SuiMoveNormalizedTypeMutableReference)
    case Vector(SuiMoveNormalizedTypeVector)
    case MoveNormalizedStructType(SuiMoveNormalizedStructType)
}
