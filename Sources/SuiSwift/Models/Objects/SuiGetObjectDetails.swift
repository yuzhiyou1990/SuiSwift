//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

public enum SuiGetObjectDetails: Decodable{
    case SuiObject(SuiObject)
    case ObjectId(SuiObjectId)
    case SuiObjectRef(SuiObjectRef)
}
