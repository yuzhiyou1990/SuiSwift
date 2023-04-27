//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

extension Base64String: Encodable{
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }
}
extension Base64String: Decodable{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = Base64String(value: str)
            return
        }
        throw SuiError.RPCError.DecodingError("Base64String Decoder Error")
    }
}
