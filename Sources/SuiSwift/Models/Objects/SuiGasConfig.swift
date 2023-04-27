//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation
public struct SuiGasConfig{
    public var budget: String?
    public var price: String?
    public var payment: [SuiObjectRef]?
    public var owner: SuiAddress?
    public init(budget: String? = "1000", price: String? = "5", payment: [SuiObjectRef]? = nil, owner: SuiAddress? = nil) {
        self.budget = budget
        self.price = price
        self.payment = payment
        self.owner = owner
    }
}
