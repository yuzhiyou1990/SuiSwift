//
//  DappBuilder.swift
//  MathWallet5
//
//  Created by li shuai on 2023/5/4.
//

import Foundation
import SuiSwift
import BigInt
import PromiseKit

protocol SuiTransactionStructDapp{
    static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner
}
extension SuiTransactionBuilder{
    public static func ParseDAppTransaction(dic: [String: Any]) throws -> SuiTransactionBuilder{
        guard let sender = dic["sender"] as? String,
              let version = dic["version"] as? Int,
              let inputs = dic["inputs"] as? [[String: Any]],
              let transactions = dic["transactions"] as? [[String: Any]] else{
            throw SuiError.BuildTransactionError.InvalidSerializeData
        }
        let blockInputs = try inputs.map { dic in
            return try SuiMoveCallTransaction.input(dic: dic)
        }
        let blockTransactions = try transactions.map({ dic in
            return try SuiTransactionInner.transactionType(dic: dic)
        })
        return SuiTransactionBuilder(version: version, sender: try SuiAddress(value: SuiAddress.normalizeSuiAddress(address: sender)), expiration: nil, inputs: blockInputs, transactions: blockTransactions)
    }
}

extension SuiTransactionInner{
    static func transactionType(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let kind = dic["kind"] as? String else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid kind")
        }
        guard let transaction = SuiTransactionInner.transactionType()[kind] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid Transaction Type")
        }
        return try transaction.getTransaction(dic: dic)
    }
    static func transactionType() -> [String: SuiTransactionStructDapp.Type]{
        return [SuiMoveCallTransaction.kind: SuiMoveCallTransaction.self,
                SuiTransferObjectsTransaction.kind: SuiTransferObjectsTransaction.self,
                SuiSplitCoinsTransaction.kind: SuiSplitCoinsTransaction.self,
                SuiMergeCoinsTransaction.kind: SuiMergeCoinsTransaction.self,
                SuiMakeMoveVecTransaction.kind: SuiMakeMoveVecTransaction.self,
                SuiPublishTransaction.kind: SuiPublishTransaction.self,
                SuiUpgradeTransaction.kind: SuiUpgradeTransaction.self]
    }
}

extension SuiMoveCallTransaction: SuiTransactionStructDapp{
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let target = dic["target"] as? String,
              let argumentDics = dic["arguments"] as? [[String: AnyObject]] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid Target")
        }
        let typeArguments = dic["typeArguments"] as? [String]
        let transaction = try SuiMoveCallTransaction(target: target, typeArguments: typeArguments, arguments: argumentDics)
        return .MoveCall(transaction)
    }
}

extension SuiTransferObjectsTransaction: SuiTransactionStructDapp{
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let objectsDics = dic["objects"] as? [[String: AnyObject]],
              let addressDic = dic["address"] as? [String: AnyObject] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid objects")
        }
        let transaction = try SuiTransferObjectsTransaction(objects: objectsDics, address: addressDic)
        return .TransferObjects(transaction)
    }
}

extension SuiSplitCoinsTransaction: SuiTransactionStructDapp{
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let amountsDics = dic["amounts"] as? [[String: AnyObject]],
              let coinDic = dic["coin"] as? [String: AnyObject] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SplitCoins Type")
        }
        let transaction = try SuiSplitCoinsTransaction(coin: coinDic, amounts: amountsDics)
        return .SplitCoins(transaction)
    }
}

extension SuiMergeCoinsTransaction: SuiTransactionStructDapp{
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let sourcesDics = dic["sources"] as? [[String: AnyObject]],
              let destinationDic = dic["destination"] as? [String: AnyObject] else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid MergeCoins Type")
        }
        let transaction = try SuiMergeCoinsTransaction(destination: destinationDic, sources: sourcesDics)
        return .MergeCoins(transaction)
    }
}

extension SuiMakeMoveVecTransaction: SuiTransactionStructDapp{
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let objectsDics = dic["objects"] as? [[String: AnyObject]]  else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid MakeMove Type")
        }
        return .MakeMoveVec(try .init(type: nil, objects: objectsDics))
    }
}

extension SuiPublishTransaction: SuiTransactionStructDapp{
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let compiledModules = dic["modules"] as? [Dictionary<String, UInt8>],
              let dependencies = dic["compiledModules"] as? [String]  else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid MakeMove Type")
        }
        return .Publish(try .init(modules: compiledModules, dependencies: dependencies))
    }
}

extension SuiUpgradeTransaction: SuiTransactionStructDapp{
    public static func getTransaction(dic: [String: Any]) throws -> SuiTransactionInner{
        guard let compiledModules = dic["modules"] as? [Dictionary<String, UInt8>],
              let dependencies = dic["compiledModules"] as? [String],
              let packageIdStr = dic["packageId"] as? String,
              let ticketDic = dic["destination"] as? [String: AnyObject]   else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid UpgradeTransaction Type")
        }
        return .Upgrade(try .init(modules: compiledModules, dependencies: dependencies, packageId: packageIdStr, ticket: ticketDic))
    }
}
