//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
/**
 * Kind of a TypeTag which is represented by a Move type identifier.
 */
public struct SuiStructTag{
    public var address: SuiAddress
    public var module: String
    public var name: String
    public var typeParams: [SuiTypeTag]?
    public init(address: SuiAddress, module: String, name: String, typeParams: [SuiTypeTag]?) {
        self.address = address
        self.module = module
        self.name = name
        self.typeParams = typeParams
    }
}

extension SuiStructTag: BorshCodable{
    public func serialize(to writer: inout Data) throws {
        try address.serialize(to: &writer)
        try module.serialize(to: &writer)
        try name.serialize(to: &writer)
        if let typeParams = typeParams {
            try typeParams.serialize(to: &writer)
        }else{
            try UVarInt(0).serialize(to: &writer)
        }
    }
    
    public init(from reader: inout BinaryReader) throws {
        address = try SuiAddress(from: &reader)
        module = try String(from: &reader)
        name = try String(from: &reader)
        typeParams = try [SuiTypeTag](from: &reader)
    }
}
