//
//  File.swift
//  
//
//  Created by li shuai on 2022/10/26.
//

import Foundation
import CryptoSwift

public struct SuiAddress: Codable{
    public var value: String
    public var publicKeyHash: Data
    public static let ADDRESS_SIZE = 40
    public static var DATASIZE: Int{
        return SuiAddress.ADDRESS_SIZE / 2
    }
    public init(value: String) throws{
        self.value = value
        self.publicKeyHash = Data(hex: value.stripHexPrefix())
    }
}

extension SuiAddress{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = try SuiAddress(value: str)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiAddress Decoder Error")
    }
}
