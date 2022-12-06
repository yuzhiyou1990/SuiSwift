//
//  File.swift
//  
//
//  Created by li shuai on 2022/10/26.
//

import Foundation

public struct SuiAddress: Codable{
    public var value: String
    public init(value: String) {
        self.value = value
    }
}

extension SuiAddress{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = SuiAddress(value: str)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiAddress Decoder Error")
    }
}
