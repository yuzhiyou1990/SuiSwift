//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/11.
//

import Foundation

public enum SuiJsonValue{
    case Boolean(Bool)
    case Number(String)
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
   public func moveTypeEncode(type: String, to writer: inout Data) throws{
       switch type {
       case "Bool":
           guard let booValue = value() as? Bool else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try booValue.serialize(to: &writer)
       case "U8":
           if let number = value() as? String{
               try UInt8(number)?.serialize(to: &writer)
           }
       case "U64":
           if let number = value() as? String{
               try UInt64(number)?.serialize(to: &writer)
           }
       case "U128":
           if let number = value() as? String{
               try UInt128(number)?.serialize(to: &writer)
           }
       case "Address":
           guard let address = value() as? String else{
               throw SuiError.DataSerializerError.ParseError("Serialize SuiJsonValue Error, suiTypeTag: \(type)")
           }
           try SuiAddress(value: address).serialize(to: &writer)
       case "U16":
           if let number = value() as? String{
               try UInt16(number)?.serialize(to: &writer)
           }
       case "U32":
           if let number = value() as? String{
               try UInt32(number)?.serialize(to: &writer)
           }
       case "U256":
           if let number = value() as? String{
               try UInt256(number)?.serialize(to: &writer)
           }
       default:
           break
       }
   }
}
