//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiObjectRef: Decodable{
    /** Base58 string representing the object digest */
    public var digest: SuiTransactionDigest
    /** Hex code as string representing the object id */
    public var objectId: SuiAddress
    /** Object version */
    public var version: UInt64
    public init(digest: String, objectId: String, version: UInt64) {
        self.digest = Base58String(value: digest)
        self.objectId = try! SuiAddress(value: objectId)
        self.version = version
    }
}

extension SuiObjectRef{
    enum CodingKeys: String, CodingKey {
        case digest
        case objectId
        case version
    }
    public init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        self.digest = try container.decode(SuiTransactionDigest.self, forKey: .digest)
        self.objectId = try container.decode(SuiAddress.self, forKey: .objectId)
        if let _version = try? container.decode(String.self, forKey: .version){
            self.version = UInt64(_version) ?? 0
        } else {
            self.version = try container.decode(UInt64.self, forKey: .version)
        }
    }
}
