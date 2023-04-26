//
//  BorshEncoder.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation

public struct BorshEncoder {
    public init() {}
    public func encode<T>(_ value: T) throws -> Data where T : BorshSerializable {
        var writer = Data()
        try value.serialize(to: &writer)
        return writer
    }
}
