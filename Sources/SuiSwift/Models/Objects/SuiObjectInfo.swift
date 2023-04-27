//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiObjectInfo: Decodable{
    public var objectId: SuiAddress
    public var version: UInt64
    public var digest: SuiTransactionDigest
    public var type: String
    public var owner: SuiObjectOwner
    public var previousTransaction: String
}
