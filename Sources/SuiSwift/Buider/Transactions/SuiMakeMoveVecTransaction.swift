//
//  File.swift
//  
//
//  Created by li shuai on 2023/5/10.
//

import Foundation
public struct SuiMakeMoveVecTransaction: SuiTransactionStruct{
    public static let kind: String = "MakeMoveVec"
    public let type: [SuiTypeTag]?
    public let objects: [SuiTransactionArgumentType]
    public init(type: [SuiTypeTag]?, objects: [SuiTransactionArgumentType]) {
        self.type = type
        self.objects = objects
    }
    public init(type: [String]?, objects: [[String: AnyObject]]) throws{
        self.type = try type?.map({ str in
            try SuiTypeTag.parseFromStr(str: str)
        })
        self.objects = try objects.map({ dic in
            try SuiMakeMoveVecTransaction.defaultType(dic: dic)
        })
    }
    public func inner() -> SuiTransactionInner {
        return .MakeMoveVec(self)
    }
}
