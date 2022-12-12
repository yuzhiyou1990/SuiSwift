//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/1.
//

import Foundation
import AnyCodable

public typealias SuiObjectId = String
public struct SuiRpcApiVersion{
    public var major: Int
    public var minor: Int
    public var patch: Int
}

public enum SuiObjectOwner: Decodable{
    public struct SuiShared: Decodable{
        public var initial_shared_version: Int
    }
    case AddressOwner(SuiAddress)
    case ObjectOwner(SuiAddress)
    case SingleOwner(SuiAddress)
    case Immutable(String)
    case Shared(SuiShared)
    case Unknow(Error)
}

public struct SuiObjectInfo: Decodable{
    public var objectId: SuiAddress
    public var version: UInt64
    public var digest: SuiTransactionDigest
    public var type: String
    public var owner: SuiObjectOwner
}

public enum SuiObjectStatus: String, Decodable{
    case Exists
    case NotExists
    case Deleted
}

public typealias SuiTransactionDigest = Base64String

public struct SuiObjectRef: Decodable{
    /** Base64 string representing the object digest */
    public var digest: SuiTransactionDigest
    /** Hex code as string representing the object id */
    public var objectId: SuiAddress
    /** Object version */
    public var version: UInt64
    public init(digest: String, objectId: String, version: UInt64) {
        self.digest = Base64String(value: digest)
        self.objectId = try! SuiAddress(value: objectId)
        self.version = version
    }
}

public struct SuiData: Decodable{
    public enum DataObject: Decodable{
        case MoveObject(SuiMoveObject)
        case MovePackage(SuiMovePackage)
        case ParseError(String)
    }
    public var dataType: String?
    public var dataObject: DataObject
}

public struct SuiMovePackage: Decodable{
    /** A mapping from module name to disassembled Move bytecode */
    public var disassembled: AnyCodable
}

public struct SuiObject: Decodable{
    /** The meat of the object */
    public var data: SuiData
    /** The owner of the object */
    public var owner: SuiObjectOwner
    /** The digest of the transaction that created or last mutated this object */
    public var previousTransaction: SuiTransactionDigest
    /**
       * The amount of SUI we would rebate if this object gets deleted.
       * This number is re-calculated each time the object is mutated based on
       * the present storage gas price.
       */
    public var storageRebate: Int
    public var reference: SuiObjectRef
}

public enum SuiGetObjectDetails: Decodable{
    case SuiObject(SuiObject)
    case ObjectId(SuiObjectId)
    case SuiObjectRef(SuiObjectRef)
}

public struct SuiGetObjectDataResponse: Decodable{
    public var status: SuiObjectStatus
    public var details: SuiGetObjectDetails
}

public struct SuiMoveObject: Decodable{
    /** Move type (e.g., "0x2::coin::Coin<0x2::sui::SUI>") */
    public var type: String
    /** Fields and values stored inside the Move object */
    public var fields: AnyCodable
    public var has_public_transfer: Bool?
}
