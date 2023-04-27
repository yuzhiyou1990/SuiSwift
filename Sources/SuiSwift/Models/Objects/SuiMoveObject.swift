//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
import AnyCodable

public struct SuiMoveObject: Decodable{
    
    /** Move type (e.g., "0x2::coin::Coin<0x2::sui::SUI>") */
    public var type: String
    /** Fields and values stored inside the Move object */
    public var fields: AnyCodable
    public var has_public_transfer: Bool?
}

extension SuiMoveObject: SuiObjectDataFull{
    public func getType() -> String?{
        return type
    }
    public func getObjectId() -> String? {
        guard let dic = fields.value as? [String: Any],
              let id = dic["id"] as? [String: String] else {
            return nil
        }
        return id["id"]
    }
    public func getBalance() -> String{
        guard let dic = fields.value as? [String: Any],
              let balanceI = dic["balance"] as? String else{
            return "0"
        }
        return "\(balanceI)"
    }
}
