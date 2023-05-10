//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation

public struct SuiMergeCoinsTransaction: SuiTransactionStruct{
    public static let kind: String = "MergeCoins"
    public let destination: SuiTransactionArgumentType
    public let sources: [SuiTransactionArgumentType]
    public init(destination: SuiTransactionArgumentType, sources: [SuiTransactionArgumentType]) {
        self.destination = destination
        self.sources = sources
    }
    public init(destination: [String: AnyObject], sources: [[String: AnyObject]]) throws{
        self.destination = try SuiMergeCoinsTransaction.defaultType(dic: destination)
        self.sources = try sources.map({ dic in
            try SuiMergeCoinsTransaction.defaultType(dic: destination)
        })
    }
    public func inner() -> SuiTransactionInner {
        return .MergeCoins(self)
    }
}
