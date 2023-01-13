//
//  File.swift
//
//
//  Created by li shuai on 2022/11/21.
//

import Foundation
import AnyCodable

public enum SuiExecuteTransactionRequestType: String{
    case ImmediateReturn
    case WaitForTxCert
    case WaitForEffectsCert
    case WaitForLocalExecution
}
public typealias EpochId = Int
public struct SuiChangeEpoch: Decodable{
    public var epoch: EpochId
    public var storage_charge: Int
    public var computation_charge: Int
}

public typealias SuiAuthoritySignature = String
public enum SuiGenericAuthoritySignature: Decodable{
    case SuiAuthoritySignature(String)
    case SuiAuthoritySignatures([String])
    case Unknow(Error)
}

public struct SuiAuthorityQuorumSignInfo: Decodable{
    public var epoch: EpochId
    public var signature: SuiGenericAuthoritySignature
}
public struct SuiCertifiedTransaction: Decodable{
    public var transactionDigest: SuiTransactionDigest
    public var data: AnyCodable
    public var txSignature: String
    public var authSignInfo: SuiAuthorityQuorumSignInfo
}

public struct SuiExecutionStatus: Decodable{
    public var status: String
    public var error: String?
}

// https://github.com/MystenLabs/sui/blob/5e20e6569416525bef8101357adda8a9a3c66a63/sdk/typescript/src/types/transactions.ts
public struct SuiGasCostSummary: Decodable{
    public var computationCost: Int
    public var storageCost: Int
    public var storageRebate: Int
}

public struct SuiOwnedObjectRef: Decodable{
    public var owner: SuiObjectOwner
    public var reference: SuiObjectRef
}

public struct SuiTransactionEffects: Decodable{
    /** The status of the execution */
    public var status: SuiExecutionStatus
    public var gasUsed: SuiGasCostSummary
    /** The object references of the shared objects used in this transaction. Empty if no shared objects were used. */
    public var sharedObjects: [SuiObjectRef]?
    /** The transaction digest */
    public var transactionDigest: SuiTransactionDigest
    /** ObjectRef and owner of new objects created */
    public var created: [SuiOwnedObjectRef]?
    /** ObjectRef and owner of mutated objects, including gas object */
    public var mutated: [SuiOwnedObjectRef]?
    /**
       * ObjectRef and owner of objects that are unwrapped in this transaction.
       * Unwrapped objects are objects that were wrapped into other objects in the past,
       * and just got extracted out.
       */
    public var unwrapped: [SuiOwnedObjectRef]?
    /** Object Refs of objects now deleted (the old refs) */
    public var deleted: [SuiObjectRef]?
    /** Object refs of objects now wrapped in other objects */
    public var wrapped: [SuiObjectRef]?
    /**
       * The updated gas object reference. Have a dedicated field for convenient access.
       * It's also included in mutated.
       */
    public var gasObject: SuiOwnedObjectRef
    /** The events emitted during execution. Note that only successful transactions emit events */
      // TODO: properly define type when this is being used
    public var events: [AnyCodable]?
    /** The set of transaction digests this transaction depends on */
    public var dependencies: [SuiTransactionDigest]?
}

public struct SuiCertifiedTransactionEffects: Decodable{
    public var effects: SuiTransactionEffects
}
public struct SuiEffectsCert: Decodable{
    public var certificate: SuiCertifiedTransaction
    public var effects: SuiCertifiedTransactionEffects
}

public struct SuiTxCert: Decodable{
    public var certificate: SuiCertifiedTransaction
}

public struct SuiImmediateReturn: Decodable{
    public var tx_digest: String
}

public enum SuiExecuteTransactionResponse: Decodable{
    case ImmediateReturn(SuiImmediateReturn)
    case TxCert(SuiTxCert)
    case EffectsCert(SuiEffectsCert)
    case Unknow(Error)
}
// https://github.com/MystenLabs/sui/blob/d5045359107fc7abae5d466b8d71ee009d2eb96e/crates/sui-framework/sources/governance/sui_system.move
public struct SuiSystemState: Decodable{
    public var chain_id: UInt64
    public var epoch: UInt64
    public var reference_gas_price: UInt64
    public var validators: AnyCodable
}

extension SuiGenericAuthoritySignature{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .SuiAuthoritySignature(str)
            return
        }
        if let strArray = try? container.decode([String].self) {
            self = .SuiAuthoritySignatures(strArray)
            return
        }
        self = .Unknow(SuiError.TransactionResponseError.DecodingError(modelName: "SuiGenericAuthoritySignature"))
    }
}

extension SuiExecuteTransactionResponse{
    enum CodingKeys: String, CodingKey {
        case ImmediateReturn
        case EffectsCert
        case TxCert
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let immediateReturn = try? container.decode(SuiImmediateReturn.self, forKey: .ImmediateReturn){
            self = .ImmediateReturn(immediateReturn)
            return
        }
        if let effectsCert = try? container.decode(SuiEffectsCert.self, forKey: .EffectsCert){
            self = .EffectsCert(effectsCert)
            return
        }
        if let txCert = try? container.decode(SuiTxCert.self, forKey: .TxCert){
            self = .TxCert(txCert)
            return
        }
        self = .Unknow(SuiError.TransactionResponseError.DecodingError(modelName: "SuiExecuteTransactionResponse"))
    }
}
