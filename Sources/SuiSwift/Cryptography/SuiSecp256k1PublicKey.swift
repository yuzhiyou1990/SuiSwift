//
//  SuiEd25519PublicKey.swift
//
//
//  Created by li shuai on 2023/01/04.
//

import Foundation
import CryptoSwift
import Blake2
public struct SuiSecp256k1PublicKey: SuiPublicKey{
    public var publicKey: Data
    private static let PUBLIC_KEY_SIZE = 33
    public init(publicKey: Data) throws {
        guard publicKey.count == SuiSecp256k1PublicKey.PUBLIC_KEY_SIZE else{
            throw SuiError.KeypairError.InvalidPublicKey
        }
        self.publicKey = publicKey
    }
    
    public func toBase64() throws -> String {
        return publicKey.bytes.toBase64()
    }
    
    public func toSuiAddress() throws -> SuiAddress {
        var tmp = [UInt8]()
        tmp.append(SuiSignatureScheme.Secp256k1.rawValue)
        publicKey.forEach{tmp.append($0)}
        let hash = try Blake2.hash(.b2b, size: 32, bytes: tmp)[0..<32]
        let address = hash.toHexString()
        return try SuiAddress(value: address.addHexPrefix())
    }
}
