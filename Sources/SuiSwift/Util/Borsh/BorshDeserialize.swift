//
//  BorshDeserializable.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation
import Base58Swift

public protocol BorshDeserializable {
    init(from reader: inout BinaryReader) throws
}

extension UInt8: BorshDeserializable {}
extension UInt16: BorshDeserializable {}
extension UInt32: BorshDeserializable {}
extension UInt64: BorshDeserializable {}
extension UInt128: BorshDeserializable {}
extension Int8: BorshDeserializable {}
extension Int16: BorshDeserializable {}
extension Int32: BorshDeserializable {}
extension Int64: BorshDeserializable {}
extension Int128: BorshDeserializable {}

public extension FixedWidthInteger {
    init(from reader: inout BinaryReader) throws {
        var value: Self = .zero
        let bytes = reader.read(count: UInt32(MemoryLayout<Self>.size))
        let size = withUnsafeMutableBytes(of: &value, { bytes.copyBytes(to: $0) } )
        assert(size == MemoryLayout<Self>.size)
        self = Self(littleEndian: value)
    }
}

extension UVarInt: BorshDeserializable {
    public init(from reader: inout BinaryReader) throws {
        let bytes = Array(reader.remainingBytes())
        var i: Int = 0
        var v: UInt32 = 0, b: UInt8 = 0, by: UInt8 = 0
        repeat {
            b = bytes[i]
            v |= UInt32(b & 0x7F) << by
            by += 7
            i += 1
        } while (b & 0x80) != 0 && by < 32
        self.value = v
        let _ = reader.read(count: UInt32(i))
    }
}

extension VarData: BorshDeserializable {
    public init(from reader: inout BinaryReader) throws {
        let count = try UVarInt.init(from: &reader).value
        let bytes = reader.read(count: count)
        self.data = Data(bytes)
    }
}

extension Bool: BorshDeserializable {
    public init(from reader: inout BinaryReader) throws {
        var value: Self = false
        let bytes = reader.read(count: UInt32(MemoryLayout<Self>.size))
        let size = withUnsafeMutableBytes(of: &value, { bytes.copyBytes(to: $0) } )
        assert(size == MemoryLayout<Self>.size)
        self = value
    }
}

extension String: BorshDeserializable {
    public init(from reader: inout BinaryReader) throws {
        let count: UInt32 = try UVarInt.init(from: &reader).value
        let bytes = reader.read(count: count)
        guard let value = String(bytes: bytes, encoding: .utf8) else { throw SuiError.BCSError.DeserializeError() }
        self = value
    }
}

extension ASCIIString: BorshDeserializable {
    public init(from reader: inout BinaryReader) throws {
        let count: UInt32 = try UVarInt.init(from: &reader).value
        let bytes = reader.read(count: count)
        guard let value = String(bytes: bytes, encoding: .ascii) else { throw SuiError.BCSError.DeserializeError() }
        self = .init(value: value)
    }
}
extension SuiAddress: BorshDeserializable {
    public init(from reader: inout BinaryReader) throws {
        let bytes = reader.read(count: UInt32(SuiAddress.ADDRESS_SIZE / 2))
        let value = Data(bytes: bytes, count: SuiAddress.ADDRESS_SIZE / 2).toHexString()
        self = try .init(value: value.addHexPrefix())
    }
}

extension Base64String: BorshDeserializable{
    public init(from reader: inout BinaryReader) throws {
        let count: UInt32 = try UVarInt.init(from: &reader).value
        let bytes = reader.read(count: count)
        let value = Data(bytes: bytes, count: Int(count)).base64EncodedString()
        self = .init(value: value)
    }
}

extension Base58String: BorshDeserializable{
    public init(from reader: inout BinaryReader) throws {
        let count: UInt32 = try UVarInt.init(from: &reader).value
        let bytes = reader.read(count: count)
        let value = Base58.base58FromBytes(bytes)
        self = .init(value: value)
    }
}

extension Array: BorshDeserializable where Element: BorshDeserializable {
    public init(from reader: inout BinaryReader) throws {
        let count: UInt32 = try UVarInt.init(from: &reader).value
        self = try Array<UInt32>(0..<count).map {_ in try Element.init(from: &reader) }
    }
}

extension Set: BorshDeserializable where Element: BorshDeserializable & Equatable {
    public init(from reader: inout BinaryReader) throws {
        self = try Set(Array<Element>.init(from: &reader))
    }
}

