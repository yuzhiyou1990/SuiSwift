//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation
public struct SuiPublishTransaction: SuiTransactionStruct{
    public static let kind: String = "Publish"
    public let modules: [[UInt8]]
    public let dependencies: [SuiAddress]
    public init(modules: [[UInt8]], dependencies: [SuiAddress]) {
        self.modules = modules
        self.dependencies = dependencies
    }
    
    public init(modules: [Dictionary<String, UInt8>], dependencies: [String]) throws{
        var modulesList = [[UInt8]]()
        modules.forEach { pureMap in
            var pures = [UInt8]()
            pureMap.sorted(by: {$0.0 < $1.0}).forEach { (_, value) in
                pures.append(value)
            }
            modulesList.append(pures)
        }
        self.modules = modulesList
        self.dependencies = try dependencies.map { str in
            try SuiAddress(value: str)
        }
    }
    
    public func inner() -> SuiTransactionInner {
        return .Publish(self)
    }
}
