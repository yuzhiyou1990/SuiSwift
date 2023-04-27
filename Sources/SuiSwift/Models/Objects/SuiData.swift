//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

public struct SuiData: Decodable{
    public enum DataObject: Decodable{
        case MoveObject(SuiMoveObject)
        case MovePackage(SuiMovePackage)
        case ParseError(String)
    }
    public var dataType: String?
    public var dataObject: DataObject
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
