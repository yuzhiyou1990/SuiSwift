//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public let SUI_SYSTEM_ADDRESS = "0x3"
public let SUI_FRAMEWORK_ADDRESS = "0x2"
public let MOVE_STDLIB_ADDRESS = "0x1"
public let OBJECT_MODULE_NAME = "object"
public let UID_STRUCT_NAME = "UID"
public let ID_STRUCT_NAME = "ID"
public let SUI_TYPE_ARG = "\(SUI_FRAMEWORK_ADDRESS)::sui::SUI"
public let VALIDATORS_EVENTS_QUERY = "0x3::validator_set::ValidatorEpochInfoEventV2"
public let COIN_TYPE = "\(SUI_FRAMEWORK_ADDRESS)::coin::Coin"

// `sui::pay` module is used for Coin management (split, join, join_and_transfer etc);
public let PAY_MODULE_NAME = "pay"
public let PAY_SPLIT_COIN_VEC_FUNC_NAME = "split_vec"
public let PAY_JOIN_COIN_FUNC_NAME = "join"
public let COIN_TYPE_ARG_REGEX = "^0x2::coin::Coin<(.+)>$"
public let SUI_CoinSymbol = "SUI"

public let STD_ASCII_MODULE_NAME = "ascii"
public let STD_ASCII_STRUCT_NAME = "String"

public let STD_UTF8_MODULE_NAME = STD_ASCII_STRUCT_NAME.lowercased()
public let STD_UTF8_STRUCT_NAME = STD_ASCII_STRUCT_NAME

public let STD_OPTION_STRUCT_NAME = "Option"
public let STD_OPTION_MODULE_NAME = STD_OPTION_STRUCT_NAME.lowercased()


public let SUI_VECTOR_REGEX = "^vector<(.+)>$"
public let SUI_STRUCT_REGEX = "^([^:]+)::([^:]+)::([^<]+)(<(.+)>)?"
public let SUI_STRUCT_TYPE_TAG_REGEX = "^[^<]+<(.+)>$"
public let SUI_STRUCT_NAME_REGEX = "^([^<]+)"

#if os(Linux)
import SwiftGlibc
#else
import Darwin
#endif

public class RegEx {
    var reg = regex_t()
    public init?(_ pattern: String) {
        guard 0 == regcomp(&reg, pattern, REG_EXTENDED) else {
            return nil
        }
    }
    deinit {
        regfree(&reg)
    }
    
    /// test if the current string contains a certain pattern
    /// - parameters:
    ///   - string: string to search
    /// - returns: true if found
    public func exists( _ string: String) -> Bool {
        return match(string).count > 0
    }
    
    /// using regular expression to extract substrings
    /// - parameters:
    ///   - string: String to search
    ///   - limitation: Int, the maximum number of matches allowed to find
    /// - returns:
    ///   [Range] - an array, each element is a range of match
    public func match(_ string: String) -> [Range<String.Index>] {
        
        // set up an empty result set
        var found = [Range<String.Index>]()
        
        // prepare pointers
        guard let me = strdup(string) else {
            return found
        }
        
        // string length
        let sz = Int(string.count)
        let limitation = sz
        
        // cursor of the string buffer
        var cursor = me
        
        // allocate a buffer for the outcomes
        let m = UnsafeMutablePointer<regmatch_t>.allocate(capacity: limitation)
        defer {
#if swift(>=4.1)
            m.deallocate()
#else
            m.deallocate(capacity: limitation)
#endif
            free(me)
        }
        
        // loop until all matches were found
        while 0 == regexec(&reg, cursor, limitation, m, 0) {
            
            // retrieve each matches from the pointer buffer
            for i in 0 ... limitation - 1 {
                
                // if reach the end, the position marker will be -1
                let p = m.advanced(by: i).pointee
                guard p.rm_so > -1 else {
                    break
                }//end guard
                
                // append outcomes to return set
                let offset = me.distance(to: cursor)
                let start = String.Index(encodedOffset: Int(p.rm_so) + offset)
                let end = String.Index(encodedOffset: Int(p.rm_eo) + offset)
                found.append(start ..< end)
            }//next i
            
            cursor = cursor.advanced(by: Int(m.pointee.rm_eo))
        }
        
        return found
    }
}
