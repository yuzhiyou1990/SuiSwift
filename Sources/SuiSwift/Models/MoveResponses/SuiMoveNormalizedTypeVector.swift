//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiMoveNormalizedTypeVector: Decodable{
    public var vector: SuiMoveNormalizedType
    enum CodingKeys: String, CodingKey {
        case vector = "Vector"
    }
}
