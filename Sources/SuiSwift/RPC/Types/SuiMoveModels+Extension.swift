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

extension SuiStructType: Equatable{
    public static func == (lhs: SuiStructType, rhs: SuiStructType) -> Bool {
        return lhs.address == rhs.address && lhs.module == rhs.module && lhs.name == rhs.name
    }
    static var RESOLVED_SUI_ID : SuiStructType {
        SuiStructType(address: SUI_FRAMEWORK_ADDRESS, module: OBJECT_MODULE_NAME, name: ID_STRUCT_NAME, type_arguments: [])
    }
    static var RESOLVED_ASCII_STR : SuiStructType {
        SuiStructType(address: MOVE_STDLIB_ADDRESS, module: STD_ASCII_MODULE_NAME, name: STD_ASCII_STRUCT_NAME, type_arguments: [])
    }
    static var RESOLVED_UTF8_STR : SuiStructType {
        SuiStructType(address: MOVE_STDLIB_ADDRESS, module: STD_UTF8_MODULE_NAME, name: STD_UTF8_STRUCT_NAME, type_arguments: [])
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
