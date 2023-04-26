//
//  SuiEd25519Keypair+Extension.swift
//  
//
//  Created by li shuai on 2022/12/27.
//

import Foundation

extension SuiEd25519Keypair{
    public static func deriveKey(path: String, key: Data, chainCode: Data) -> (key: Data, chainCode: Data) {
        let paths = path.components(separatedBy: "/")

        var newKey = key
        var newChainCode = chainCode
        
        for path in paths {
            if path == "m" {
                continue
            }
            var hpath:UInt32 = 0
            if path.contains("'") {
                let pathnum = UInt32(path.replacingOccurrences(of: "'", with: "")) ?? 0
                hpath = pathnum + 0x80000000
            } else {
                hpath = UInt32(path) ?? 0
            }
            let pathData32 = UInt32(hpath)
            let pathDataBE = withUnsafeBytes(of: pathData32.bigEndian, Array.init)
            var data = Data()
            data.append([0], count: 1)
            data.append(newKey)
            data.append(pathDataBE,count: 4)
            
            let d = data.hmacSHA512(key: newChainCode)
            newKey = d.subdata(in: 0..<32)
            newChainCode = d.subdata(in:32..<64)
        }
        return (newKey, newChainCode)
    }
}
