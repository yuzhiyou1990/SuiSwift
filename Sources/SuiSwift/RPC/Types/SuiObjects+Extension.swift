//
//  SuiObjects+Extension.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation
import Base58Swift

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

extension Base58String: Decodable{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = Base58String(value: str)
            return
        }
        throw SuiError.RPCError.DecodingError("Base58String Decoder Error")
    }
}
extension Base64String: Encodable{
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }
}
extension Base64String: Decodable{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = Base64String(value: str)
            return
        }
        throw SuiError.RPCError.DecodingError("Base64String Decoder Error")
    }
}
extension SuiData{
    enum CodingKeys: String, CodingKey {
        case dataType
    }
    public func balance() -> String{
        switch dataObject{
        case .MoveObject(let moveObject): return moveObject.getBalance()
        case .MovePackage(_), .ParseError(_):  return "0"
        }
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(String.self, forKey: .dataType){
            dataType = value
        }
        
        let singleContainer = try decoder.singleValueContainer()
        if let package = try? singleContainer.decode(SuiMovePackage.self) {
            dataObject = .MovePackage(package)
            return
        }
        if let moveObject = try? singleContainer.decode(SuiMoveObject.self) {
            dataObject = .MoveObject(moveObject)
            return
        }
        dataObject = .ParseError("SuiData Parse Error")
    }
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
