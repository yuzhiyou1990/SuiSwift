//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

public struct SuiMoveNormalizedStructType: Decodable{
    public var structType: SuiStructType
    enum CodingKeys: String, CodingKey {
        case structType = "Struct"
    }
}
