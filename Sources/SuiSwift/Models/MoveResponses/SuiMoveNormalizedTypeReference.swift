//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiMoveNormalizedTypeReference: Decodable{
    public var reference: SuiMoveNormalizedType
    enum CodingKeys: String, CodingKey {
        case reference = "Reference"
    }
}
