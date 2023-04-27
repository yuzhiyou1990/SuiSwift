//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

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
extension SuiObjectOwner{
    enum CodingKeys: String, CodingKey {
        case AddressOwner
        case ObjectOwner
        case SingleOwner
        case Immutable
        case Shared
        case Unknow
    }
    public init(from decoder: Decoder) throws {
        if  let container = try? decoder.container(keyedBy: CodingKeys.self){
            if let value = try? container.decode(SuiAddress.self, forKey: .AddressOwner){
                self = .AddressOwner(value)
                return
            }
            if let value = try? container.decode(SuiAddress.self, forKey: .ObjectOwner){
                self = .ObjectOwner(value)
                return
            }
            if let value = try? container.decode(SuiObjectOwner.SuiShared.self, forKey: .Shared){
                self = .Shared(value)
                return
            }
        }
        if let singleContainer = try? decoder.singleValueContainer(){
            if let name = try? singleContainer.decode(String.self) {
                self = .Immutable(name)
                return
            }
        }
        self = .Unknow(SuiError.RPCError.DecodingError("SuiObjectOwner Parse Error"))
    }
}
