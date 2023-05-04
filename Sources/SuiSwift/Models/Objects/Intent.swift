//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/24.
//

import Foundation
import Blake2
public enum SuiIntentScope: UInt8{
    case TransactionData = 0
    case TransactionEffects = 1
    case CheckpointSummary = 2
    case PersonalMessage = 3
}
public enum SuiAppId: UInt8{
    case Sui = 0
}

public enum SuiIntentVersion: UInt8{
    case V0 = 0
}

// transactionData
extension Data{
    public func signTxnBytesWithKeypair(keypair: SuiKeypair, scope: SuiIntentScope = .TransactionData) throws -> SuiExecuteTransactionBlock{
        let intentMessage = messageWithIntent(scope: scope, message: self.bytes)
        let hash = try Blake2.hash(.b2b, size: 32, bytes: intentMessage)
        let signData = try keypair.signData(message: hash)
        guard let encodeStr = Data(self.bytes).encodeBase64Str() else {
            throw SuiError.BuildTransactionError.InvalidSerializeData
        }
        var serialized_sig = [UInt8]()
        serialized_sig.append(keypair.getKeyScheme().rawValue)
        serialized_sig.append(contentsOf: signData.bytes)
        serialized_sig.append(contentsOf: keypair.publicData.bytes)
        
        guard let _signature = Data(Array(serialized_sig)).encodeBase64Str() else {
            throw SuiError.BuildTransactionError.InvalidSignData
        }
        return SuiExecuteTransactionBlock(transactionBlock: Base64String(value: encodeStr), signature: [Base64String(value: _signature)], requestType: .WaitForEffectsCert)
    }
    public func intentWithScope(scope: SuiIntentScope) -> [UInt8]{
        return [scope.rawValue, SuiIntentVersion.V0.rawValue, SuiAppId.Sui.rawValue]
    }
    public func messageWithIntent(scope: SuiIntentScope, message: [UInt8]) -> [UInt8]{
        let intent = intentWithScope(scope: scope)
        var intentMessage = [UInt8]()
        intentMessage.append(contentsOf: intent)
        intentMessage.append(contentsOf: message)
        return intentMessage
    }
}

