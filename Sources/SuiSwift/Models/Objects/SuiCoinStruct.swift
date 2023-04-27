//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

public struct SuiCoinStruct: Decodable{
    public let coinType: String
    public let coinObjectId: SuiAddress
    public let version: SuiObjectVersion
    public let digest: SuiTransactionDigest
    public let balance: String
    public let lockedUntilEpoch: UInt64?
    public let previousTransaction: SuiTransactionDigest
}
