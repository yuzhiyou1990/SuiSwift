//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public typealias SuiMoveFunctionArgTypes = [SuiMoveFunctionArgType]
// move call
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
