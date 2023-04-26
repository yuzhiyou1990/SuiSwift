//
//  SuiEd25519PublicKey.swift
//
//
//  Created by li shuai on 2023/01/04.
//

import Foundation
import CryptoSwift
import Secp256k1Swift
import BIP32Swift
import BIP39swift

public struct SuiSecp256k1Keypair: SuiKeypair{
    public var secretKey: Data
    public var publicData: Data
    
    public init(secretKey: Data) throws{
        self.secretKey = secretKey
        guard let pubKey = SECP256K1.privateToPublic(privateKey: secretKey, compressed: true) else {
            throw SuiError.KeypairError.InvalidSecretKey
        }
        self.publicData = pubKey
    }
    public init(key: Data) throws {
        try self.init(secretKey: key)
    }
    public init(mnemonics: String, derivationPath: SuiDerivationPath = .DERVIATION_PATH_PURPOSE_SECP256K1(address_index: "0")) throws{
        try self.init(mnemonics: mnemonics, path: derivationPath.PATH())
    }
    
    public init(mnemonics: String, path: String) throws{
        guard let seed = BIP39.seedFromMmemonics(mnemonics) else {
            throw SuiError.KeypairError.InvalidMnemonics
        }
        try self.init(seed: seed, path: path)
    }
    
    public init(seed: Data, path: String) throws{
        guard let node = HDNode(seed: seed),
              let treeNode = node.derive(path: path),
              let privateKey = treeNode.privateKey else {
            throw SuiError.KeypairError.InvalidSeed
        }
        try self.init(secretKey: privateKey)
    }
    
    public static func randomKeyPair() throws -> SuiKeypair {
        guard let privateKey = SECP256K1.generatePrivateKey() else {
            throw SuiError.KeypairError.NotExpected
        }
        return try self.init(secretKey: privateKey)
    }
    
    public func getPublicKey() throws -> any SuiPublicKey {
        return try SuiSecp256k1PublicKey(publicKey: self.publicData)
    }
    
    public func signData(message: Data) throws -> Data {
        guard let base64Tx = message.encodeBase64Str() else{
            throw SuiError.KeypairError.SignError
        }
        let signedData = SECP256K1.signForRecovery(hash: Data(Array(base64: base64Tx)).sha256(), privateKey: secretKey)
        guard let signData = signedData.serializedSignature else {
            throw SuiError.KeypairError.SignError
        }
        return signData
    }
    
    public func getKeyScheme() -> SuiSignatureScheme {
        return .Secp256k1
    }
}
