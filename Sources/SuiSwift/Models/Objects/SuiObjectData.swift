//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
import AnyCodable

public protocol SuiObjectDataI{
    func getType() -> String?
}

public protocol SuiObjectDataFull: SuiObjectDataI{
    func getBalance() -> String
}
public typealias SuiObjectDigest = String
public struct SuiObjectData: Decodable{
    public let objectId: String
    public let version: SuiObjectVersion
    public let digest: SuiObjectDigest
    public let type: String?
    public let content: SuiParsedData?
    public let bcs: AnyCodable?
    public let owner: SuiObjectOwner?
    public let previousTransaction: SuiTransactionDigest?
    public let storageRebate: String?
    public let display: AnyCodable?
}

extension SuiObjectData{
    public func getObjectReference() -> SuiObjectRef{
        return SuiObjectRef(digest: digest, objectId: self.objectId, version: version.value())
    }
}

extension SuiObjectData: SuiObjectDataI{
    public func getType() -> String? {
        return self.type
    }
}
