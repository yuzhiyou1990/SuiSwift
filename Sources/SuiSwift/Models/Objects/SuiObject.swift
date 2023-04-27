//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

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

extension SuiObject{
    public func type() -> String?{
        switch data.dataObject{
        case .MoveObject(let moveObject): return moveObject.getType()
        case .MovePackage(_), .ParseError(_): return nil
        }
    }
    public func id() -> String? {
        switch data.dataObject{
        case .MovePackage(_), .ParseError(_): return nil
        case .MoveObject(let moveObject): return moveObject.getObjectId()
        }
    }
    public func balance() -> String {
        switch data.dataObject{
        case .MovePackage(_), .ParseError(_): return "0"
        case .MoveObject(let moveObject): return moveObject.getBalance()
        }
    }
}
