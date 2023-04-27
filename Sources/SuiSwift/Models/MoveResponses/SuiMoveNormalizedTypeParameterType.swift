//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public typealias SuiMoveTypeParameterIndex = UInt64
public struct SuiMoveNormalizedTypeParameterType: Decodable{
    public var typeParameter: SuiMoveTypeParameterIndex
    enum CodingKeys: String, CodingKey {
        case typeParameter = "TypeParameter"
    }
}
