//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
import AnyCodable

public struct SuiMovePackage: Decodable{
    /** A mapping from module name to disassembled Move bytecode */
    public var disassembled: AnyCodable
}
