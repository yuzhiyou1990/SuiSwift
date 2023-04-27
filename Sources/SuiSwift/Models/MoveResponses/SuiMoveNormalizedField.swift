//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiMoveNormalizedField: Decodable{
    public var name: String
    public var type_: SuiMoveNormalizedType
    enum CodingKeys: String, CodingKey {
        case name
        case type_ = "type"
    }
}
