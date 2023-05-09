//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/11.
//

import Foundation

public enum SuiJsonValue{
    case Boolean(Bool)
    case Number(UInt64)
    case Str(String)
    case CallArg(SuiCallArg)
    case Array([SuiJsonValue])
}
extension SuiJsonValue{
    public func isMutableSharedObjectInput() -> Bool{
        if case .CallArg(let callArg) = self{
            if case .Object(let objArg) = callArg{
                if case .Shared(let shardObjArg) = objArg{
                    return shardObjArg.mutable
                }
            }
        }
        return false
    }
    public func isSharedObjectInput() -> Bool{
        if case .CallArg(let callArg) = self{
            if case .Object(let objArg) = callArg{
                if case .Shared(_) = objArg{
                    return true
                }
            }
        }
        return false
    }
}
// MARK: move call 需要详细测试一下类型
extension SuiJsonValue{
   public func value() -> AnyObject{
       switch self{
       case .Str(let str):
           return str as AnyObject
       case .Array(let values):
           return values as AnyObject
       case .Boolean(let bool):
           return bool as AnyObject
       case .Number(let number):
           return number as AnyObject
       case .CallArg(let array):
           return array as AnyObject
       }
   }
   public func encode(type: SuiTypeTag, to writer: inout Data) throws{
       switch type {
       case .ASBool:
           guard let booValue = value() as? Bool else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try booValue.serialize(to: &writer)
       case .ASUInt8:
           guard let number = value() as? String else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try UInt8(number)!.serialize(to: &writer)
       case .ASUInt64:
           guard let number = value() as? UInt64 else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try number.serialize(to: &writer)
       case .ASUInt128:
           guard let number = value() as? String else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try UInt128(number)!.serialize(to: &writer)
       case .Address:
           guard let address = value() as? String else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try SuiAddress(value: address).serialize(to: &writer)
       case .ASUInt16:
           guard let number = value() as? String else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try UInt16(number)!.serialize(to: &writer)
       case .ASUInt32:
           guard let number = value() as? String else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try UInt32(number)!.serialize(to: &writer)
       case .ASUInt256:
           guard let number = value() as? String else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try UInt256(number)!.serialize(to: &writer)
       default:
           break
       }
   }
}

extension Int64 {
    var unsigned: UInt64 {
        let valuePointer = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee }
    }
}

extension UInt64 {
    var signed: Int64 {
        let valuePointer = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: Int64.self, capacity: 1) { $0.pointee }
    }
}
