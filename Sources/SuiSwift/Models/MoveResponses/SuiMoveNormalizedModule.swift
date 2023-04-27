//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public typealias SuiMoveNormalizedModules = [String: SuiMoveNormalizedModule]

public struct SuiMoveNormalizedModule: Decodable{
    public var fileFormatVersion: Int
    public var address: String
    public var name: String
    public var friends: [SuiMoveModuleId]
    public var structs: [String: SuiMoveNormalizedStruct]
    public var exposedFunctions: [String: SuiMoveNormalizedFunction]?
}
