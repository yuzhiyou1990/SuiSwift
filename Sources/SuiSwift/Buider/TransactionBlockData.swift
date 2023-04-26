//
//  File.swift
//  
//
//  Created by li shuai on 2023/3/30.
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
public enum SuiJsonValue{
    case Boolean(Bool)
    case Number(UInt64)
    case Str(String)
    case CallArg(SuiCallArg)
    case Array([SuiJsonValue])
}
extension SuiJsonValue{
    public func isMutableSharedObjectInput() -> Bool{
        if case .CallArg(let callArg) = self{
            if case .Object(let objArg) = callArg{
                if case .Shared(let shardObjArg) = objArg{
                    return shardObjArg.mutable
                }
            }
        }
        return false
    }
    public func isSharedObjectInput() -> Bool{
        if case .CallArg(let callArg) = self{
            if case .Object(let objArg) = callArg{
                if case .Shared(_) = objArg{
                    return true
                }
            }
        }
        return false
    }
}
public class SuiTransactionBlockDataBuilder{
    public var version: Int
    public var sender: SuiAddress?
    public var expiration: SuiTransactionExpiration?
    public var gasConfig: SuiGasConfig
    public var inputs: [SuiTransactionBlockInput]?
    public var transactions: [SuiTransactionInner]?
    public init(version: Int = 1, sender: SuiAddress? = nil, expiration: SuiTransactionExpiration? = nil, gasConfig: SuiGasConfig = SuiGasConfig(), inputs: [SuiTransactionBlockInput]? = [SuiTransactionBlockInput](), transactions: [SuiTransactionInner]? = [SuiTransactionInner]()) {
        self.version = version
        self.sender = sender
        self.expiration = expiration
        self.gasConfig = gasConfig
        self.inputs = inputs
        self.transactions = transactions
    }
    
    public func updateInput(input: SuiTransactionBlockInput) throws{
        guard let inputs = self.inputs else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing inputs")
        }
        guard let index = inputs.map({ $0.index }).filter({ $0 == input.index }).first else {
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("UpdateInput Error, invalid index")
        }
        self.inputs![Int(index)].value = input.value
    }
}
extension SuiTransactionBlockDataBuilder{
    func build() throws -> Data{
        guard let sender = self.sender else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing sender")
        }
        guard let payments = self.gasConfig.payment, let price = self.gasConfig.price, let budget = self.gasConfig.budget else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing gasConfig")
        }
        guard let inputs = self.inputs else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing inputs")
        }
        guard let transactions = self.transactions else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing transactions")
        }
        let values = try inputs.map { input in
            guard case .CallArg(let callArg) = input.value else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("invalid input value")
            }
            return callArg
        }
        let programmableTransaction = SuiProgrammableTransaction(inputs: values, transactions: transactions)
        let transactionData = SuiTransactionData.V1(SuiTransactionDataV1(kind: .ProgrammableTransaction(programmableTransaction), sender: sender, gasData: SuiGasData(payment: payments, owner: gasConfig.owner ?? sender, price: UInt64(price)!, budget: UInt64(budget)!), expiration: self.expiration ?? .None))
        var data = Data()
        try transactionData.serialize(to: &data)
        return data
    }
}
extension SuiTransactionBlockDataBuilder{
    //prepare
    public func resolveTransactions(moveModulesToResolve: inout [SuiMoveCallTransaction], objectsToResolve: inout [SuiObjectsToResolve]) throws{
        try transactions?.forEach({ transactionInner in
            if case .MoveCall(let moveCallTransaction) = transactionInner {
                var needsResolution = false
                for argument in moveCallTransaction.arguments {
                    if case .TransactionBlockInput(let input) = argument {
                        switch input.value{
                        case .CallArg(_):
                            needsResolution = false
                        default:
                            needsResolution = true
                        }
                    }
                    continue
                }
                if needsResolution {
                    moveModulesToResolve.append(moveCallTransaction)
                }
                return
            }
            try transactionInner.encodeInput(inputs: &self.inputs, objectsToResolve: &objectsToResolve)
        })
    }
}

extension SuiTransactionStruct{
    public func handleResolve(inputs: inout [SuiTransactionBlockInput]?, index: Int, objectsToResolve: inout [SuiObjectsToResolve]) throws {
        guard let _inputs = inputs, index <= _inputs.count - 1 else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Missing input \(index)")
        }
        let input = _inputs[index]
        if case .CallArg(_) = input.value{
            return
        }
        if case .Str(let _str) = input.value{
            if input.type == "object"{
                objectsToResolve.append(SuiObjectsToResolve(id: _str, input: inputs![index], normalizedType: nil))
            }else{
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Unexpected input format.")
            }
        }
        else{
            throw SuiError.BuildTransactionError.ConstructTransactionDataError("Unexpected input format.")
        }
    }
}
extension SuiMoveCallTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws {
       try self.arguments.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
    }
}

extension SuiTransferObjectsTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws {
        try self.objects.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
        if case .TransactionBlockInput(let blockInput) =  self.address {
            try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
        }
    }
}

extension SuiSplitCoinsTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws {
        if case .TransactionBlockInput(let blockInput) =  self.coin {
            try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
        }
        try self.amounts.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
    }
}
extension SuiMergeCoinsTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws {
        if case .TransactionBlockInput(let blockInput) =  self.destination {
            try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
        }
        try self.sources.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
    }
}
extension SuiMakeMoveVecTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws{
        try self.objects.forEach { transactionArgumentType in
            if case .TransactionBlockInput(let blockInput) =  transactionArgumentType {
                try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
            }
        }
    }
}

extension SuiPublishTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws{
        debugPrint("kind !== 'Input'")
    }
}

extension SuiUpgradeTransaction{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws{
        if case .TransactionBlockInput(let blockInput) =  self.ticket {
            try self.handleResolve(inputs: &inputs, index: Int(blockInput.index), objectsToResolve: &objectsToResolve)
        }
    }
}

extension SuiTransactionInner{
    public func encodeInput(inputs: inout [SuiTransactionBlockInput]?, objectsToResolve: inout [SuiObjectsToResolve]) throws{
        switch self {
        case .MoveCall(let suiMoveCallTransaction):
            try suiMoveCallTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .TransferObjects(let suiTransferObjectsTransaction):
            try suiTransferObjectsTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .SplitCoins(let suiSplitCoinsTransaction):
            try suiSplitCoinsTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .MergeCoins(let suiMergeCoinsTransaction):
            try suiMergeCoinsTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .Publish(let suiPublishTransaction):
            try suiPublishTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .MakeMoveVec(let suiMakeMoveVecTransaction):
            try suiMakeMoveVecTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        case .Upgrade(let suiUpgradeTransaction):
            try suiUpgradeTransaction.encodeInput(inputs: &inputs, objectsToResolve: &objectsToResolve)
        }
    }
}

extension SuiTransactionBlockDataBuilder{
    // 把input基本类型转为 callArg
    public func serializationPureType(apiMoveParams: [SuiMoveNormalizedType], originMoveArguments: [SuiTransactionArgumentType], objectsToResolve: inout [SuiObjectsToResolve]) throws{
        guard let inputs = self.inputs else {
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Movecall InputValue Is Invalid")
        }
        for (index, param) in apiMoveParams.enumerated() {
            guard case .TransactionBlockInput(let input) = originMoveArguments[index], let inputValue = inputs[Int(input.index)].value else {
                throw SuiError.BuildTransactionError.ConstructTransactionDataError("Movecall InputValue Is Invalid")
            }
            if case .CallArg(_) = inputValue {
                continue
            }
            let serType = try Serializer.getPureSerializationType(normalizedType: param, argVal: inputValue)
            if let pureType = serType.flatMap({ $0 }) {
                self.inputs?[Int(input.index)].value = .CallArg(.Pure(pureType))
                continue
            }

            if let _ = param.extractStructTag(), case .MoveNormalizedTypeParameterType(_) = param{
                guard let value = inputValue.value() as? String else {
                    throw SuiError.DataSerializerError.ParseError("expect the argument to be an object id string, got {\(inputValue.value())}")
                }
                objectsToResolve.append(SuiObjectsToResolve(id: value, input: self.inputs![Int(input.index)], normalizedType: param))
                return
            }
        }
    }
}
