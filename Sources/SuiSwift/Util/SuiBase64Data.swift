//
//  File.swift
//  
//
//  Created by li shuai on 2022/10/31.
//

import Foundation
import CryptoSwift

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
        return  String(data: data, encoding: .utf8)
    }
}
