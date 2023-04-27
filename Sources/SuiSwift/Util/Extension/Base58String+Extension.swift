//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
import Base58Swift

extension Base58String: Decodable{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = Base58String(value: str)
            return
        }
        throw SuiError.RPCError.DecodingError("Base58String Decoder Error")
    }
}
