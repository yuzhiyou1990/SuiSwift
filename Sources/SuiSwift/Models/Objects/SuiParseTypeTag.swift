//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation
public struct SuiParseTypeTag{
    // normalizedType === 'string
    public static func parseArgWithType(normalizedType type: String, jsonValue arg: SuiJsonValue) -> BorshSerializable?{
        if type == "address" {
            guard let value =  arg.value() as? String,
                  let address = try? SuiAddress(value: value) else{
                return nil
            }
            return address
        } else if type == "bool" {
            guard let value = arg.value() as? Bool else{
                return nil
            }
            return value
        } else if type == "u8" {
            if let value = arg.value() as? String {
                return UInt8(value) ?? 0
            }
            if let value = arg.value() as? UInt8 {
                return value
            }
        } else if type == "u16" {
            if let value = arg.value() as? String {
                return UInt16(value) ?? 0
            }
            if let value = arg.value() as? UInt16 {
                return value
            }
        } else if type == "u32" {
            if let value = arg.value() as? String {
                return UInt32(value) ?? 0
            }
            if let value = arg.value() as? UInt32 {
                return value
            }
        } else if type == "u64" {
            if let value = arg.value() as? String {
                return UInt64(value) ?? 0
            }
            if let value = arg.value() as? UInt64 {
                return value
            }
            
        } else if type == "u128" {
            if let value = arg.value() as? String {
                return UInt128(value)
            }
            if let value = arg.value() as? UInt64 {
                return UInt128(value)
            }
        }
//        else if type == "u256" {
//            if let value = arg.value() as? String {
//                return UInt256(1)
//            }
//            if let value = arg.value() as? UInt64 {
//                return UInt256(1)
//            }
//        }
        return nil
    }
}
