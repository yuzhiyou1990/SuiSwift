//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/19.
//

import Foundation

public struct SuiSignedTransaction{
    public var txnBytes: String
    public var signatureScheme: SuiSignatureScheme
    public var signature: String
    public var pubkey: String
    init(txnBytes: String, signatureScheme: SuiSignatureScheme, signature: String, pubkey: String) {
        self.txnBytes = txnBytes
        self.signatureScheme = signatureScheme
        self.signature = signature
        self.pubkey = pubkey
    }
}

extension SuiTransactionData{
    public  func signWithKeypair(keypair: SuiKeypair) throws -> SuiSignedTransaction{
        var serializeTransactionData = Data()
        try self.serialize(to: &serializeTransactionData)
        guard let _txnBytes = serializeTransactionData.encodeBase64Str() else {
            throw SuiError.BuildTransactionError.InvalidSerializeData
        }
        // See: sui/crates/sui-types/src/intent.rs
        // This is currently hardcoded with [IntentScope::TransactionData = 0, Version::V0 = 0, AppId::Sui = 0]
        let INTENT_BYTES: [UInt8] = [0, 0, 0]
        var intentMessage = [UInt8]()
        intentMessage.append(contentsOf: INTENT_BYTES)
        intentMessage.append(contentsOf: serializeTransactionData.bytes)
        
        let signData = try keypair.signData(message: Data(Array(intentMessage)))
        let publicKey = try keypair.getPublicKey().toBase64()
        guard let _signature = signData.encodeBase64Str() else {
            throw SuiError.BuildTransactionError.InvalidSignData
        }
        return SuiSignedTransaction(txnBytes: _txnBytes, signatureScheme: keypair.getKeyScheme(), signature: _signature, pubkey: publicKey)
    }
}
