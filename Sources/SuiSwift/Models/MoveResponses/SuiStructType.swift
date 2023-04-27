//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiStructType: Decodable{
    public var address: String
    public var module: String
    public var name: String
    public var typeArguments: [SuiMoveNormalizedType]
}

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
