//
//  SuiEd25519Keypair.swift
//  
//
// Created by li shuai on 2022/12/20.
//

import Foundation
import TweetNacl
import BIP39swift

public struct SuiEd25519Keypair: SuiKeypair{
    public var secretKey: Data
    public var publicData: Data
    public init(secretKey: Data) throws{
        self.secretKey = secretKey
        let pubKey = try NaclSign.KeyPair.keyPair(fromSecretKey: secretKey).publicKey
        self.publicData = pubKey
    }
    public init(key: Data) throws {
        if key.count > 32{
            try self.init(secretKey: key)
        } else{
            try self.init(seed: key)
        }
    }
    public init(seed: Data, path: String = "") throws {
        let masterKeyData = seed.hmacSHA512(key: "ed25519 seed".data(using: .utf8)!)
        let key = masterKeyData.subdata(in: 0..<32)
        let chainCode = masterKeyData.subdata(in: 32..<64)
        let newSeed = SuiEd25519Keypair.deriveKey(path: path, key: key, chainCode: chainCode).key
        try self.init(seed: newSeed)
    }
    public init(seed: Data) throws{
        guard seed.count == 32 else {
            throw SuiError.KeypairError.InvalidSeed
        }
        let keyPair = try NaclSign.KeyPair.keyPair(fromSeed: seed)
        try self.init(secretKey: keyPair.secretKey)
    }
    
    public static func randomKeyPair() throws -> SuiKeypair{
        let keyPair = try NaclSign.KeyPair.keyPair()
        return try self.init(secretKey: keyPair.secretKey)
    }
    public init(mnemonics: String, derivationPath: SuiDerivationPath = .DERVIATION_PATH_PURPOSE_ED25519(address_index: "0")) throws{
        try self.init(mnemonics: mnemonics, path: derivationPath.PATH())
    }
    public init(mnemonics: String, path: String) throws{
        guard let seed = BIP39.seedFromMmemonics(mnemonics) else {
            throw SuiError.KeypairError.InvalidMnemonics
        }
        try self.init(seed: seed, path: path)
    }
    
    public func getPublicKey() throws -> any SuiPublicKey {
        return try SuiEd25519PublicKey(publicKey: self.publicData)
    }
    
    public func signData(message: Data) throws -> Data {
        guard let base64Tx = message.encodeBase64Str() else{
            throw SuiError.KeypairError.SignError
        }
        return try NaclSign.signDetached(message: Data(Array(base64: base64Tx)), secretKey: secretKey)
    }
    public func getKeyScheme() -> SuiSignatureScheme {
        return .ED25519
    }
}
