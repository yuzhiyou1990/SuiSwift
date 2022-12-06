//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/4.
//

import Foundation
import BigInt
import AnyCodable

public let SUI_FRAMEWORK_ADDRESS = "0x2"
public let MOVE_STDLIB_ADDRESS = "0x1"
public let OBJECT_MODULE_NAME = "object"
public let UID_STRUCT_NAME = "UID"
public let ID_STRUCT_NAME = "ID"
public let SUI_TYPE_ARG = "\(SUI_FRAMEWORK_ADDRESS)::sui::SUI"
public let COIN_TYPE = "\(SUI_FRAMEWORK_ADDRESS)::coin::Coin"

// `sui::pay` module is used for Coin management (split, join, join_and_transfer etc);
public let PAY_MODULE_NAME = "pay"
public let PAY_SPLIT_COIN_VEC_FUNC_NAME = "split_vec"
public let PAY_JOIN_COIN_FUNC_NAME = "join"
public let COIN_TYPE_ARG_REGEX = "^0x2::coin::Coin<(.+)>$"
public let SUI_CoinSymbol = "SUI"
/**
 * Utility class for 0x2::coin
 * as defined in https://github.com/MystenLabs/sui/blob/ca9046fd8b1a9e8634a4b74b0e7dabdc7ea54475/sui_programmability/framework/sources/Coin.move#L4
 */

public protocol SuiObjectData{
    func getType() -> String?
    func getObjectId() -> String?
}

public protocol SuiObjectDataFull: SuiObjectData{
    func getBalance() -> String
}

public struct SuiCoin{
    
    public static func isCoin<T>(data: T) -> Bool where T: SuiObjectData{
        guard let type = data.getType() else{
            return false
        }
        return type.hasPrefix(COIN_TYPE)
    }
    public static func getCoinTypeArg<T>(data: T) -> String? where T: SuiObjectData{
        guard let type = data.getType() else{
            return nil
        }
        let ranges = type.match(pattern: COIN_TYPE_ARG_REGEX)
        let found:[String] = ranges.map { String(type[$0]) }
        guard found.count >= 2 else {
            return nil
        }
        return found[1]
    }
    
    public static func isSUI<T>(data: T) -> Bool where T: SuiObjectData{
        guard let arg = SuiCoin.getCoinTypeArg(data: data) else{
            return false
        }
        return getCoinSymbol(coinTypeArg: arg) == SUI_CoinSymbol
    }
    
    public static func getCoinSymbol(coinTypeArg: String) -> String{
        guard let index = coinTypeArg.lastIndex(of: ":") else{
            return ""
        }
        return String(coinTypeArg[coinTypeArg.index(index, offsetBy: 1)...])
    }
    
    public static func getCoinStructTag(coinTypeArg: String) -> SuiStructTag?{
        let args = coinTypeArg.components(separatedBy: "::")
        guard args.count == 3 else{
            return nil
        }
        return SuiStructTag(address: args[0], module: args[1], name: args[2], typeParams: [])
    }
    
    public static func getID<T>(data: T) -> SuiObjectId? where T: SuiObjectData{
        return data.getObjectId()
    }
    
    /**
       * Convenience method for select coin objects that has a balance greater than or equal to `amount`
       *
       * @param amount coin balance
       * @param exclude object ids of the coins to exclude
       * @return a list of coin objects that has balance greater than `amount` in an ascending order
       */
    public static func selectCoinsWithBalanceGreaterThanOrEqual<T>(coins: [T], amount: BigInt, exclude: [SuiObjectId] = []) -> [T] where T: SuiObjectDataFull{
        coins.filter { coin in
            guard let id = coin.getObjectId() else{
                return false
            }
            return !exclude.contains(id) && (getBalance(data: coin) >= amount )
        }
    }
    public static func getBalance<T>(data: T) -> BigUInt where T: SuiObjectDataFull{
        if isCoin(data: data){
            return BigUInt(data.getBalance(), radix: 10) ?? BigUInt(0)
        }
        return BigUInt(0)
    }
}

extension SuiGetObjectDataResponse: SuiObjectDataFull{
    public func getType() -> String?{
        if case let SuiGetObjectDetails.SuiObject(suiObject) = details {
            return suiObject.type()
        }
        return nil
    }
    public func getObjectId() -> String? {
        if case let SuiGetObjectDetails.SuiObject(suiObject) = details {
            return suiObject.id()
        }
        return nil
    }
    public func getBalance() -> String {
        if case let SuiGetObjectDetails.SuiObject(suiObject) = details {
            return suiObject.balance()
        }
        return "0"
    }
}

extension SuiObjectInfo: SuiObjectData{
    public func getType() -> String?{
        return type
    }
    
    public func getObjectId() -> String? {
        return objectId.value
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
              let balanceI = dic["balance"] as? Int else{
            return "0"
        }
        return "\(balanceI)"
    }
}
