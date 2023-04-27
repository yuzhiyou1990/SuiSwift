//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiMoveNormalizedFunction: Decodable{
    public var visibility: SuiMoveVisibility
    public var isEntry: Bool
    public var typeParameters: [SuiMoveAbilitySet]
    public var parameters: [SuiMoveNormalizedType]
    public var return_: [SuiMoveNormalizedType]
    enum CodingKeys: String, CodingKey {
        case visibility
        case isEntry
        case typeParameters
        case parameters
        case return_ = "return"
    }
}
