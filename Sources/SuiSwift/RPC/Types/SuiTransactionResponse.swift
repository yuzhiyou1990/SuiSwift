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
public typealias SuiAuthoritySignature = String
public struct SuiAuthorityQuorumSignInfo: Codable{
    public var epoch: EpochId
    public var signature: AnyCodable
}
public struct SuiCertifiedTransaction: Codable{
    public var transactionDigest: String
    public var data: AnyCodable
    public var txSignatures: AnyCodable
    public var authSignInfo: SuiAuthorityQuorumSignInfo
}

public struct SuiExecutionStatus: Codable{
    public var status: String
    public var error: String?
}

// https://github.com/MystenLabs/sui/blob/5e20e6569416525bef8101357adda8a9a3c66a63/sdk/typescript/src/types/transactions.ts
public struct SuiGasCostSummary: Codable{
    public var computationCost: Int
    public var storageCost: Int
    public var storageRebate: Int
}

public struct SuiTransactionEffects: Codable{
    /** The status of the execution */
    public var status: SuiExecutionStatus
    public var gasUsed: SuiGasCostSummary
    /** The object references of the shared objects used in this transaction. Empty if no shared objects were used. */
    public var sharedObjects: AnyCodable?
    /** The transaction digest */
    public var transactionDigest: String
    /** ObjectRef and owner of new objects created */
    public var created: AnyCodable?
    /** ObjectRef and owner of mutated objects, including gas object */
    public var mutated: AnyCodable?
    /**
       * ObjectRef and owner of objects that are unwrapped in this transaction.
       * Unwrapped objects are objects that were wrapped into other objects in the past,
       * and just got extracted out.
       */
    public var unwrapped: AnyCodable?
    /** Object Refs of objects now deleted (the old refs) */
    public var deleted: AnyCodable?
    /** Object refs of objects now wrapped in other objects */
    public var wrapped: AnyCodable?
    /**
       * The updated gas object reference. Have a dedicated field for convenient access.
       * It's also included in mutated.
       */
    public var gasObject: AnyCodable
    /** The events emitted during execution. Note that only successful transactions emit events */
      // TODO: properly define type when this is being used
    public var events: [AnyCodable]?
    /** The set of transaction digests this transaction depends on */
    public var dependencies: [String]?
}

public struct SuiCertifiedTransactionEffects: Codable{
    public var effects: SuiTransactionEffects
}
public struct SuiEffectsCert: Codable{
    public var certificate: SuiCertifiedTransaction
    public var effects: SuiCertifiedTransactionEffects
}
// 0.28
public struct SuiExecuteTransactionResponse: Codable{
   public var certificate: SuiCertifiedTransaction
   public var effects: AnyCodable
}
// https://github.com/MystenLabs/sui/blob/d5045359107fc7abae5d466b8d71ee009d2eb96e/crates/sui-framework/sources/governance/sui_system.move
public struct SuiSystemState: Codable{
    public var epoch: UInt64
    public var reference_gas_price: UInt64
    public var validators: AnyCodable
}
