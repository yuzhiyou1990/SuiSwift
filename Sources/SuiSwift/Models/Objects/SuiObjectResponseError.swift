//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

//public struct SuiRawMoveObject: Decodable{
//    public let type: String
//    public let hasPublicTransfer: Bool
//    public let version: SuiObjectVersion
//    public let bcsBytes: String
//}

public struct SuiObjectResponseError: Decodable{
    public let tag: String
    public let object_id: SuiObjectId?
    public let version: UInt64?
    public let digest: SuiObjectDigest?
}
