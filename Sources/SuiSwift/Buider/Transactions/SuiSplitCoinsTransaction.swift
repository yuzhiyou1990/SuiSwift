//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation
public struct SuiSplitCoinsTransaction: SuiTransactionStruct{
    public static let kind: String = "SplitCoins"
    public let coin: SuiTransactionArgumentType
    public let amounts: [SuiTransactionArgumentType]
    public init(coin: SuiTransactionArgumentType, amounts: [SuiTransactionArgumentType]) {
        self.coin = coin
        self.amounts = amounts
    }
    public init(coin: [String: AnyObject], amounts: [[String: AnyObject]]) throws{
        self.coin = try SuiSplitCoinsTransaction.defaultType(dic: coin)
        self.amounts = try amounts.map({ dic in
            let type = dic["type"] as? String
            guard let index = dic["index"] as? UInt else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SplitCoins ArgumentType")
            }
            if let value = dic["value"] as? String, let number = UInt64(value){
                return SuiTransactionArgumentType.TransactionBlockInput(.init(index: UInt16(index), value: .CallArg(try SuiInputs.Pure(value: number)), type: type))
            }
            if let number = dic["value"] as? UInt64{
                return SuiTransactionArgumentType.TransactionBlockInput(.init(index: UInt16(index), value: .CallArg(try SuiInputs.Pure(value: number)), type: type))
            }
            if let pureDic = dic["value"] as? [String: AnyObject], let value = pureDic["Pure"] as? [UInt8]{
                return SuiTransactionArgumentType.TransactionBlockInput(.init(index: UInt16(index), value: .CallArg(.Pure(value)), type: type))
            }
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Invalid SplitCoins ArgumentType")
        })
    }
    public func inner() -> SuiTransactionInner {
        return .SplitCoins(self)
    }
}
