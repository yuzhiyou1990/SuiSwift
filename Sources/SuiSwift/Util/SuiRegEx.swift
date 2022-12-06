
import Foundation
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
