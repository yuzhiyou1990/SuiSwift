//
//  File.swift
//  
//
//  Created by li shuai on 2022/10/26.
//

import Foundation

public enum SuiSignatureScheme: UInt8, Codable{
    case ED25519 = 0x00
    case Secp256k1 = 0x01
    public func name() -> String{
        switch self {
        case .ED25519:
            return "ED25519"
        case .Secp256k1:
            return "Secp256k1"
        }
    }
}

public protocol SuiPublicKey: Equatable{
    var publicKey: Data {get}
    init(publicKey: Data) throws
    func toBase64() throws -> String
    func toSuiAddress() throws -> SuiAddress
}

extension SuiPublicKey{
    public static func == (lhs: Self, rhs: Self) -> Bool{
        return lhs.publicKey == rhs.publicKey
    }
}
