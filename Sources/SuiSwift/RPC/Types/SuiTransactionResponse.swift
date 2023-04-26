//
//  SuiTransactionResponse.swift
//
//
//  Created by li shuai on 2022/12/20.
//

import Foundation
import AnyCodable

public typealias EpochId = Int

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
    public var computationCost: String
    public var storageCost: String
    public var storageRebate: String
    public var nonRefundableStorageFee: String
}

public struct SuiOwnedObjectRef: Decodable{
    public var owner: SuiObjectOwner
    public var reference: SuiObjectRef
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
