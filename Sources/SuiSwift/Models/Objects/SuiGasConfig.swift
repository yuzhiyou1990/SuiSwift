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
    public var payment: [SuiObjectRef]
    public var owner: SuiAddress?
    public init(budget: String? = "50000000", price: String? = "1000", payment: [SuiObjectRef] = [], owner: SuiAddress? = nil) {
        self.budget = budget
        self.price = price
        self.payment = payment
        self.owner = owner
    }
}
