//
//  File.swift
//  
//
//  Created by li shuai on 2023/3/30.
//

import Foundation

let STD_ASCII_MODULE_NAME = "ascii"
let STD_ASCII_STRUCT_NAME = "String"

let STD_UTF8_MODULE_NAME = STD_ASCII_STRUCT_NAME.lowercased()
let STD_UTF8_STRUCT_NAME = STD_ASCII_STRUCT_NAME

let STD_OPTION_STRUCT_NAME = "Option"
let STD_OPTION_MODULE_NAME = STD_OPTION_STRUCT_NAME.lowercased()


public struct Serializer{
    /**
       *
       * @param argVal used to do additional data validation to make sure the argVal
       * matches the normalized Move types. If `argVal === undefined`, the data validation
       * will be skipped. This is useful in the case where `normalizedType` is a vector<T>
       * and `argVal` is an empty array, the data validation for the inner types will be skipped.
       */
    public static func getPureSerializationType(normalizedType: SuiMoveNormalizedType, argVal: SuiJsonValue) throws -> [UInt8]?{
        let allowedTypes = ["Address", "Bool", "U8", "U16", "U32", "U64", "U128", "U256"]
        switch normalizedType {
        case .Str(let string):
            guard allowedTypes.contains(string), let bcsValue = SuiTypeTag.parseArgWithType(normalizedType: string.lowercased(), jsonValue: argVal)  else{
                throw SuiError.DataSerializerError.ParseError("unknown pure normalized type \(string)")
            }
            var data = Data()
            try bcsValue.serialize(to: &data)
            return data.bytes
        case .Vector(let suiMoveNormalizedTypeVector):
            if case .Str(let string) = suiMoveNormalizedTypeVector.vector, string == "U8"{
                if case .Str(let str) = argVal {
                    var data = Data()
                    try str.serialize(to: &data)
                    return data.bytes
                }
                if case .Array(let values) = argVal{
                    var argsBCS = [UInt8]()
                    for value in values {
                        let inner = try self.getPureSerializationType(normalizedType: suiMoveNormalizedTypeVector.vector, argVal: value)
                        if inner != nil{
                            argsBCS.append(contentsOf: inner!)
                            
                        } else {return nil}
                    }
                    var data = Data()
                    try argsBCS.serialize(to: &data)
                    return data.bytes
                    
                } else{
                    throw SuiError.DataSerializerError.ParseError("Expect \(argVal) to be a array")
                }
            }
            
        case .MoveNormalizedStructType(let suiMoveNormalizedStructType):
            if let value = argVal.value() as? String {
                if SuiStructType.RESOLVED_ASCII_STR == suiMoveNormalizedStructType.structType{
                    var data = Data()
                    try ASCIIString(value: value).serialize(to: &data)
                    return data.bytes
                } else if SuiStructType.RESOLVED_UTF8_STR == suiMoveNormalizedStructType.structType{
                    var data = Data()
                    try value.serialize(to: &data)
                    return data.bytes
                } else if SuiStructType.RESOLVED_SUI_ID == suiMoveNormalizedStructType.structType{
                    var data = Data()
                    try SuiAddress(value: value).serialize(to: &data)
                    return data.bytes
                } else if SuiStructType.RESOLVED_STD_OPTION == suiMoveNormalizedStructType.structType{
                    let argumentType = suiMoveNormalizedStructType.structType.typeArguments[0]
                    return try getPureSerializationType(normalizedType: argumentType, argVal: argVal)
                }
            }
        default:
            return nil
        }
        return nil
    }
}
