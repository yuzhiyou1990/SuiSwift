//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiMoveNormalizedTypeMutableReference: Decodable{
    public var mutableReference: SuiMoveNormalizedType
    enum CodingKeys: String, CodingKey {
        case mutableReference = "MutableReference"
    }
}
