//
//  File.swift
//  
//
//  Created by li shuai on 2022/12/7.
//

import Foundation
import PromiseKit

public struct SuiPublishTransaction: SuiUnserializedSignableTransaction{
    public enum CompiledModules{
        case Array([String])
        case Arrayx([[UInt64]])
    }
    public var compiledModules: CompiledModules
    public var gasPayment: SuiObjectId?
    public var gasBudget: UInt64
    public init(compiledModules: CompiledModules, gasPayment: SuiObjectId? = nil, gasBudget: UInt64) {
        self.compiledModules = compiledModules
        self.gasPayment = gasPayment
        self.gasBudget = gasBudget
    }
    public func bcsTransaction() -> Promise<SuiTransaction> {
        return Promise { seal in
            DispatchQueue.global().async{
                switch compiledModules {
                case .Array(_):
                    seal.reject(SuiError.BCSError.SerializeError("Serialize SuiPublishTransaction Error"))
                case .Arrayx(let array):
                    seal.fulfill(.PublishTx(SuiPublishTx(modules: array.map{$0.map({UInt8($0)})})))
                }
            }
        }
    }
    
    public func extractObjectIds() throws -> [SuiObjectId] {
        var objectIds = [SuiObjectId]()
        if gasPayment != nil{
            objectIds.append(gasPayment!)
        }
        return objectIds
    }
    
    public func gasObjectId() -> SuiObjectId? {
        return gasPayment
    }
}
