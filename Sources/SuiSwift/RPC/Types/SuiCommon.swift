//
//  File.swift
//  
//
//  Created by li shuai on 2023/3/30.
//

import Foundation
import AnyCodable

public typealias SuiTransactionDigest = Base58String
public typealias SuiObjectId = String
public enum SuiObjectOwner: Decodable{
    public struct SuiShared: Decodable{
        public var initial_shared_version: Int
    }
    case AddressOwner(SuiAddress)
    case ObjectOwner(SuiAddress)
    case Immutable(String)
    case Shared(SuiShared)
    case Unknow(Error)
}
