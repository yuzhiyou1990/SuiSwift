//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation

public struct SuiTransferObjectsTransaction: SuiTransactionStruct{
    public static let kind: String = "TransferObjects"
    public let objects: [SuiTransactionArgumentType]
    public let address: SuiTransactionArgumentType
    public init(objects: [SuiTransactionArgumentType], address: SuiTransactionArgumentType) {
        self.objects = objects
        self.address = address
    }
    public init(objects: [[String: AnyObject]], address: [String: AnyObject]) throws{
        self.address = try SuiTransferObjectsTransaction.defaultType(dic: address)
        self.objects = try objects.map({ dic in
            try SuiTransferObjectsTransaction.defaultType(dic: dic)
        })
    }
    public func inner() -> SuiTransactionInner {
        return .TransferObjects(self)
    }
}
