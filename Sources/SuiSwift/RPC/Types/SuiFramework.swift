//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/25.
//

import Foundation
import BigInt
import AnyCodable

public let SUI_SYSTEM_ADDRESS = "0x3"
public let SUI_FRAMEWORK_ADDRESS = "0x2"
public let MOVE_STDLIB_ADDRESS = "0x1"
public let OBJECT_MODULE_NAME = "object"
public let UID_STRUCT_NAME = "UID"
public let ID_STRUCT_NAME = "ID"
public let SUI_TYPE_ARG = "\(SUI_FRAMEWORK_ADDRESS)::sui::SUI"
public let VALIDATORS_EVENTS_QUERY = "0x3::validator_set::ValidatorEpochInfoEventV2"
public let COIN_TYPE = "\(SUI_FRAMEWORK_ADDRESS)::coin::Coin"

// `sui::pay` module is used for Coin management (split, join, join_and_transfer etc);
public let PAY_MODULE_NAME = "pay"
public let PAY_SPLIT_COIN_VEC_FUNC_NAME = "split_vec"
public let PAY_JOIN_COIN_FUNC_NAME = "join"
public let COIN_TYPE_ARG_REGEX = "^0x2::coin::Coin<(.+)>$"
public let SUI_CoinSymbol = "SUI"



public protocol SuiObjectDataI{
    func getType() -> String?
}

public protocol SuiObjectDataFull: SuiObjectDataI{
    func getBalance() -> String
}

extension SuiObjectData: SuiObjectDataI{
    
    public func getType() -> String? {
        return self.type
    }
}

extension SuiObjectResponse: SuiObjectDataI{
    public func getType() -> String? {
        return  self.data?.getType()
    }
}
public struct SuiCoin{
    
    public static func isCoin<T>(data: T) -> Bool where T: SuiObjectDataI{
        guard let type = data.getType() else{
            return false
        }
        return type.hasPrefix(COIN_TYPE)
    }
    public static func isSUI<T>(data: T) -> Bool where T: SuiObjectDataI{
        guard let arg = SuiCoin.getCoinTypeArg(data: data) else{
            return false
        }
        return getCoinSymbol(coinTypeArg: arg) == SUI_CoinSymbol
    }
    public static func getCoinTypeArg<T>(data: T) -> String? where T: SuiObjectDataI{
        guard let type = data.getType() else{
            return nil
        }
        let ranges = type.match(pattern: COIN_TYPE_ARG_REGEX)
        let found: [String] = ranges.map { String(type[$0]) }
        guard found.count >= 2 else {
            return nil
        }
        return found[1]
    }
    public static func getCoinSymbol(coinTypeArg: String) -> String{
        guard let index = coinTypeArg.lastIndex(of: ":") else{
            return ""
        }
        return String(coinTypeArg[coinTypeArg.index(index, offsetBy: 1)...])
    }
    public static func getCoinStructTag(coinTypeArg: String) -> SuiStructTag?{
        let args = coinTypeArg.components(separatedBy: "::")
        guard args.count == 3, let address = try? SuiAddress(value: args[0]) else{
            return nil
        }
        return SuiStructTag(address: address, module: args[1], name: args[2], typeParams: [])
    }
    
    public static func getBalance<T>(data: T) -> BigUInt where T: SuiObjectDataFull{
        if isCoin(data: data){
            return BigUInt(data.getBalance(), radix: 10) ?? BigUInt(0)
        }
        return BigUInt(0)
    }
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
