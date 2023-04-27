//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
import BigInt

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
