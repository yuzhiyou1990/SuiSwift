//
//  BorshSerialize.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation
import CryptoSwift
import Base58Swift
import BigInt

public protocol BorshSerializable {
    func serialize(to writer: inout Data) throws
}


extension UInt8: BorshSerializable {}
extension UInt16: BorshSerializable {}
extension UInt32: BorshSerializable {}
extension UInt64: BorshSerializable {}
extension Int8: BorshSerializable {}
extension Int16: BorshSerializable {}
extension Int32: BorshSerializable {}
extension Int64: BorshSerializable {}

public extension FixedWidthInteger {
    func serialize(to writer: inout Data) throws {
        writer.append(contentsOf: withUnsafeBytes(of: self.littleEndian) { Array($0) })
    }
}

extension UInt2X: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        writer.append(contentsOf: withUnsafeBytes(of: self.littleEndian) { Array($0) })
    }
}

extension Int2X: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        writer.append(contentsOf: withUnsafeBytes(of: self.littleEndian) { Array($0) })
    }
}

extension UVarInt: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        var vui = [UInt8]()
        var val = self.value
        while val >= 128 {
            vui.append(UInt8(val % 128))
            val /= 128
        }
        vui.append(UInt8(val))

        for i in 0..<vui.count-1 {
            vui[i] += 128
        }
        writer.append(Data(vui))
    }
}

extension VarData: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        try UVarInt(self.data.count).serialize(to: &writer)
        writer.append(self.data)
    }
}

extension Bool: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        let intRepresentation: UInt8 = self ? 1 : 0
        try intRepresentation.serialize(to: &writer)
    }
}

extension String: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        let data = Data(utf8)
        try UVarInt(data.count).serialize(to: &writer)
        writer.append(data)
    }
}

extension Base64String: BorshSerializable{
    public func serialize(to writer: inout Data) throws {
        let data = Data(Array(base64: value))
        try UVarInt(data.count).serialize(to: &writer)
        writer.append(data)
    }
}

extension Base58String: BorshSerializable{
    public func serialize(to writer: inout Data) throws {
        let bytes =  Base58.bytesFromBase58(value)
        let data = Data(bytes)
        try UVarInt(data.count).serialize(to: &writer)
        writer.append(data)
    }
}
extension ASCIIString: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        guard let data = value.data(using: .ascii) else{
            throw SuiError.BCSError.SerializeError("Serialize ASCIIString Error")
        }
        try UVarInt(data.count).serialize(to: &writer)
        writer.append(data)
    }
}
extension SuiAddress: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        var addressData: Data = Data()
        let addressValueData = Data(hex: value.stripHexPrefix())
        if  addressValueData.count != SuiAddress.DATASIZE{
            let fillData = Data(repeating: 0, count: SuiAddress.DATASIZE - addressValueData.count)
            addressData.append(fillData)
            addressData.append(Data(hex: value))
        } else {
            addressData = addressValueData
        }
        writer.append(addressData)
    }
}

extension Array: BorshSerializable where Element: BorshSerializable {
    public func serialize(to writer: inout Data) throws {
        try UVarInt(count).serialize(to: &writer)
        try forEach { try $0.serialize(to: &writer) }
    }
}
extension Set: BorshSerializable where Element: BorshSerializable & Comparable {
    public func serialize(to writer: inout Data) throws {
        try sorted().serialize(to: &writer)
    }
}
