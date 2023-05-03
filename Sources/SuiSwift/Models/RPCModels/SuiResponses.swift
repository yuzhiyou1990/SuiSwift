//
//  File.swift
//  
//
//  Created by li shuai on 2023/3/31.
//

import Foundation
import AnyCodable

public struct SuiPaginatedCoins: Decodable{
    public let data: [SuiCoinStruct]
    public let nextCursor: String
    public let hasNextPage: Bool
}
public struct SuiCoinBalance: Decodable{
    public struct SuiLockedBalance: Decodable{
        public let epochId: UInt64?
        public let number: UInt64?
    }
    public let coinType: String
    public let coinObjectCount: UInt64
    public let totalBalance: String
    public let lockedBalance: SuiLockedBalance
}

public struct SuiCoinMetadata: Decodable{
    public let symbol: String
    public let id: String?
    public let description: String
    public let decimals: UInt64
    public let name: String
    public let iconUrl: String?
}

public enum SuiParsedData: Decodable{
    case MoveObject(SuiMoveObject)
    case Package(SuiMovePackage)
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let moveObject = try? container.decode(SuiMoveObject.self) {
            self = .MoveObject(moveObject)
            return
        }
        if let package = try? container.decode(SuiMovePackage.self) {
            self = .Package(package)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiParsedData Parse Error")
    }
}

public struct SuiRawMovePackage: Decodable{
    public let id: SuiObjectId
    public let moduleMap: [String: String]
}
public enum SuiRawData: Decodable{
    case MoveObject(SuiMoveObject)
    case Package(SuiRawMovePackage)
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let moveObject = try? container.decode(SuiMoveObject.self) {
            self = .MoveObject(moveObject)
            return
        }
        if let package = try? container.decode(SuiRawMovePackage.self) {
            self = .Package(package)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiRawData Parse Error")
    }
}


public struct SuiCheckpointedObjectId: Decodable{
    public let objectId: SuiObjectId
    public let atCheckpoint: Bool?
}
public struct SuiPaginatedObjectsResponse: Decodable{
    public let data: [SuiObjectResponse]
    public let nextCursor: SuiObjectId?
    public let hasNextPage: Bool
}

extension SuiGasData: Decodable{
    enum CodingKeys: String, CodingKey {
        case payment
        case owner
        case price
        case budget
    }
    public init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        self.payment = try container.decode([SuiObjectRef].self, forKey: .payment)
        self.owner = try container.decode(SuiAddress.self, forKey: .owner)
        self.price = try container.decode(UInt64.self, forKey: .price)
        self.budget = try container.decode(UInt64.self, forKey: .budget)
    }
}

public struct SuiChangeEpoch: Decodable{
    public let kind: String
    public let epoch: String
    public let storage_charge: UInt64
    public let computation_charge: UInt64
    public let storage_rebate: UInt64
    public let epoch_start_timestamp_ms: UInt64?
}

public struct SuiConsensusCommitPrologue: Decodable{
    public let kind: String
    public let epoch: UInt64
    public let round: UInt64
    public let commit_timestamp_ms: UInt64
}

public struct SuiGenesis: Decodable{
    public let kind: String
    public let objects: [SuiObjectId]
}
public enum SuiTransactionBlockKindType: Decodable{
    case ChangeEpoch(SuiChangeEpoch)
    case ConsensusCommitPrologue(SuiConsensusCommitPrologue)
    case Genesis(SuiGenesis)
    case ProgrammableTransaction(AnyCodable)
    case Other(Error)
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let changeEpoch = try? container.decode(SuiChangeEpoch.self) {
            self = .ChangeEpoch(changeEpoch)
            return
        }
        if let consensusCommitPrologue = try? container.decode(SuiConsensusCommitPrologue.self) {
            self = .ConsensusCommitPrologue(consensusCommitPrologue)
            return
        }
        if let genesis = try? container.decode(SuiGenesis.self) {
            self = .Genesis(genesis)
            return
        }
        if let programmableTransaction = try? container.decode(AnyCodable.self) {
            self = .ProgrammableTransaction(programmableTransaction)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiTransactionBlockKindType Parse Error")
    }
}

public struct SuiTransactionBlockData: Decodable{
    public let messageVersion: String
    public let transaction: AnyCodable
    public let sender: String
    public let gasData: AnyCodable
}

public struct SuiTransactionBlock: Decodable{
    public let data: SuiTransactionBlockData
    public let txSignatures: [String]
}
public typealias SuiEpochId = String
public struct SuiTransactionEffects: Decodable{
    public let messageVersion: AnyCodable
    /** The status of the execution */
    public let status: SuiExecutionStatus
    /** The epoch when this transaction was executed */
    public let executedEpoch: SuiEpochId
    
    public let gasUsed: SuiGasCostSummary
    /** The transaction digest */
    public let transactionDigest: SuiTransactionDigest
    
    public let gasObject: SuiOwnedObjectRef
}

public struct SuiBalanceChange: Decodable{
    public let owner: SuiObjectOwner
    public let coinType: String
    public let amount: String
}

public struct SuiTransactionBlockResponse: Decodable{
    public let digest: SuiTransactionDigest
    public let transaction: SuiTransactionBlock?
    public let effects: SuiTransactionEffects?
    public let confirmedLocalExecution: Bool?
}
public enum SuiStakeStatus: String, Decodable{
    case Active
    case Pending
    case Unstaked
}
public struct SuiStakeObject: Decodable{
    public let stakedSuiId: SuiObjectId
    public let stakeRequestEpoch: SuiEpochId
    public let stakeActiveEpoch: SuiEpochId
    public let principal: UInt64
    public let status: SuiStakeStatus
    public let estimatedReward: UInt64?
}

public struct SuiDelegatedStake: Decodable{
    public let validatorAddress: SuiAddress
    public let stakingPool: SuiObjectId
    public let stakes: [SuiStakeObject]
}

public struct SuiSystemStateSummary: Decodable{
    public let epoch: UInt64
    public let protocolVersion: UInt64
    public let systemStateVersion: UInt64
    public let storageFundTotalObjectStorageRebates: UInt64
    public let storageFundNonRefundableBalance: UInt64
    public let referenceGasPrice: UInt64
    public let safeMode: Bool
    public let safeModeStorageRewards: UInt64
    public let safeModeComputationRewards: UInt64
    public let safeModeStorageRebates: UInt64
    public let safeModeNonRefundableStorageFee: UInt64
    public let epochStartTimestampMs: UInt64
    public let epochDurationMs: UInt64
    public let stakeSubsidyStartEpoch: UInt64
    public let maxValidatorCount: UInt64
    public let minValidatorJoiningStake: UInt64
    public let validatorLowStakeThreshold: UInt64
    public let validatorVeryLowStakeThreshold: UInt64
    public let validatorLowStakeGracePeriod: UInt64
    public let stakeSubsidyBalance: UInt64
    public let stakeSubsidyDistributionCounter: UInt64
    public let stakeSubsidyCurrentDistributionAmount: UInt64
    public let stakeSubsidyPeriodLength: UInt64
    public let stakeSubsidyDecreaseRate: UInt64
    public let totalStake: UInt64
    public let activeValidators: AnyCodable
    public let pendingActiveValidatorsId: String
    public let pendingActiveValidatorsSize: UInt64
    public let pendingRemovals: [UInt64]
    public let stakingPoolMappingsId: String
    public let stakingPoolMappingsSize: UInt64
    public let inactivePoolsId: String
    public let inactivePoolsSize: UInt64
    public let validatorCandidatesId: String
    public let validatorCandidatesSize: UInt64
    public let atRiskValidators: AnyCodable
    public let validatorReportRecords: AnyCodable
}

public struct SuiDryRunTransactionBlockResponse: Decodable{
    public let effects: SuiTransactionEffects
}

// transaction
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
