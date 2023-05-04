//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/21.
//

import Foundation

public enum SuiObjectVersion: Decodable{
    case NumberV(UInt64)
    case StringV(String)
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let version = try? container.decode(UInt64.self) {
            self = .NumberV(version)
            return
        }
        if let version = try? container.decode(String.self) {
            self = .StringV(version)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiObjectVersion Parse Error")
    }
    public func value() -> UInt64{
        switch self {
        case .NumberV(let uInt64):
            return uInt64
        case .StringV(let string):
            return UInt64(string)!
        }
    }
}
public struct SuiInputs{
    
    public static func Pure<T>(value: T, type: String? = nil) throws -> SuiCallArg where T: BorshCodable{
        var data = Data()
        try value.serialize(to: &data)
        return .Pure(data.bytes)
    }
    
    public static func PureWithJsonValue(value: SuiJsonValue, data: inout Data) throws {
        switch value {
        case .Boolean(let bool):
            try Pure(value: bool, data: &data)
        case .Number(let uInt64):
            try Pure(value: uInt64, data: &data)
        case .Str(let string):
            if let address = try? SuiAddress(value: string){
                try Pure(value: address, data: &data)
            } else if Int(string) != nil{
                try Pure(value: UInt64(string)!, data: &data)
            } else {
                try Pure(value: string, data: &data)
            }
        case .CallArg(_):
            break
        case .Array(let array):
           try array.forEach { jsonValue in
                try PureWithJsonValue(value: jsonValue, data: &data)
            }
        }
    }
    
    public static func Pure<T>(value: T, data: inout Data) throws where T: BorshCodable{
        try value.serialize(to: &data)
    }
    
    public static func getIdFromCallArg(arg: Any) -> String? {
        if let _arg = arg as? String{
            return SuiAddress.normalizeSuiAddress(address: _arg)
        }
        if let _arg = arg as? SuiCallArg{
            if case .Object(let objArg) = _arg {
                if case .ImmOrOwned(let objRef) = objArg{
                    return objRef.objectId.value
                }
                if case .Shared(let objRef) = objArg {
                    return objRef.objectId.value
                }
            }
        }
        return nil
    }
    
    public func isSharedObjectInput(arg: SuiCallArg) -> Bool{
        if case .Object(let objArg) = arg {
            if case .Shared(_) = objArg {
                return true
            }
        }
        return false
    }
    public func isMutableSharedObjectInput(arg: SuiCallArg) -> Bool{
        if case .Object(let objArg) = arg {
            if case .ImmOrOwned(_) = objArg{
                return true
            }
        }
        return false
    }
}
