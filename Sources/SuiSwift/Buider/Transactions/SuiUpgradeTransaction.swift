//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation

public struct SuiUpgradeTransaction: SuiTransactionStruct{
    public static let kind: String = "Upgrade"
    public let modules: [[UInt8]]
    public let dependencies: [SuiAddress]
    public let packageId: SuiAddress
    public let ticket: SuiTransactionArgumentType
    public init(modules: [[UInt8]], dependencies: [SuiAddress], packageId: SuiAddress, ticket: SuiTransactionArgumentType) {
        self.modules = modules
        self.dependencies = dependencies
        self.packageId = packageId
        self.ticket = ticket
    }
    
    public init(modules: [Dictionary<String, UInt8>], dependencies: [String], packageId: String, ticket: [String: AnyObject]) throws{
        var modulesList = [[UInt8]]()
        modules.forEach { pureMap in
            var pures = [UInt8]()
            pureMap.sorted(by: {$0.0 < $1.0}).forEach { (_, value) in
                pures.append(value)
            }
            modulesList.append(pures)
        }
        let packageId = try SuiAddress(value: packageId)
        self.modules = modulesList
        self.dependencies = try dependencies.map { str in
            try SuiAddress(value: str)
        }
        self.packageId = packageId
        self.ticket = try SuiUpgradeTransaction.defaultType(dic: ticket)
    }
    public func inner() -> SuiTransactionInner {
        return .Upgrade(self)
    }
}
