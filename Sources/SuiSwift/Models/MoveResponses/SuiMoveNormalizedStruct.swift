//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiMoveNormalizedStruct: Decodable{
    public var abilities: SuiMoveAbilitySet
    public var typeParameters: [SuiMoveStructTypeParameter]
    public var fields: [SuiMoveNormalizedField]
}
