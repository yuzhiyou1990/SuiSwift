//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation
import CryptoSwift
import CommonCrypto

public protocol SuiBase64Data{
    func encodeBase64() -> Data?
    func encodeBase64Str() -> String?
}

extension Data: SuiBase64Data{
    // data -> base64Data
    public func encodeBase64() -> Data? {
        return self.base64EncodedData()
    }
    // data -> base64String
    public func encodeBase64Str() -> String?{
        guard let data = encodeBase64() else{
            return nil
        }
        return  String(data:data, encoding: .utf8)
    }
}
extension Data {
    var bytes: Array<UInt8> {
        Array(self)
    }
    func hmacSHA512(key: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA512), key.bytes, key.count, self.bytes, self.count, &digest)
        return Data(bytes: digest)
    }
    static func toPaddedData(_ hexData: Data, maxLeng: Int = 32) -> Data {
        let paddedLength = maxLeng // 总长度为32个字节
        let dataLength = hexData.count
        
        // 如果数据已经足够长，直接返回
        guard dataLength < paddedLength else {
            return hexData
        }
        
        // 计算需要填充的0的数量
        let paddingCount = paddedLength - dataLength
        
        // 将0添加到数据的左侧，直到数据达到所需的长度
        var paddedData = Data(count: paddingCount)
        paddedData.append(hexData)
        
        return paddedData
    }
}
