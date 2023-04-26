//
//  String+Extension.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation

extension String {
    func addHexPrefix() -> String {
        if !self.hasPrefix("0x") {
            return "0x" + self
        }
        return self
    }
    func stripHexPrefix() -> String {
        if self.hasPrefix("0x") {
            let indexStart = self.index(self.startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }
    /// find string ranges
    /// - parameters:
    ///   - pattern: string to recognize
    /// - return: a string range array
    public func match(pattern: String) -> [Range<String.Index>] {
        guard let reg = RegEx(pattern) else {
            return []
        }
        return reg.match(self)
    }
    
}
