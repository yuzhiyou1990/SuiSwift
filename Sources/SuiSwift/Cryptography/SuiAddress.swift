//
//  SuiAddress.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation
import CryptoSwift
//0x0b747f5e46ba9050e3fa071b6388c94df3b0d98b9ee642a42207222fb779319f
public struct SuiAddress: Codable{
    public var value: String
    public var publicKeyHash: Data
    public static let ADDRESS_SIZE = 64
    public static var DATASIZE: Int{
        return SuiAddress.ADDRESS_SIZE / 2
    }
    public init(value: String) throws{
        guard value.stripHexPrefix().count == SuiAddress.ADDRESS_SIZE else{
            throw SuiError.KeypairError.InvalidAddress
        }
        self.value = value
        self.publicKeyHash = Data(hex: value.stripHexPrefix())
    }
    
    public static func normalizeSuiAddress(address: String) -> String{
        var str = address.stripHexPrefix()
        while str.count < ADDRESS_SIZE {
            str = "0" + str
        }
        return str.lowercased()
    }
}

extension SuiAddress{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = try SuiAddress(value: SuiAddress.normalizeSuiAddress(address: str))
            return
        }
        throw SuiError.RPCError.DecodingError("SuiAddress Decoder Error")
    }
}

extension SuiAddress: Equatable{
    public static func == (lhs: SuiAddress, rhs: SuiAddress) -> Bool {
        return lhs.value.stripHexPrefix().uppercased() == rhs.value.stripHexPrefix().uppercased()
    }
}
