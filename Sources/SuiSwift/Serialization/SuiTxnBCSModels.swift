//
//  File.swift
//
//
//  Created by li shuai on 2022/11/1.
//

import Foundation
import BigInt

public protocol SuiBSCTransactionObject{}
// ========== Move Call Tx ===========

/**
 * A reference to a shared object.
 */
public struct SuiSharedObjectRef{
    /** Hex code as string representing the object id */
    public var objectId: SuiAddress
    /** The version the object was shared at */
    public var initialSharedVersion: UInt64
    public var mutable: Bool
    public init(objectId: String, initialSharedVersion: UInt64, mutable: Bool) {
        self.objectId = try! SuiAddress(value: objectId)
        self.initialSharedVersion = initialSharedVersion
        self.mutable = mutable
    }
}
/**
 * An object argument.
 */

public enum SuiObjectArg{
    case ImmOrOwned(SuiObjectRef)
    case Shared(SuiSharedObjectRef)
}
/**
 * An argument for the transaction. It is a 'meant' enum which expects to have
 * one of the optional properties. If not, the BCS error will be thrown while
 * attempting to form a transaction.
 *
 * Example:
 * ```js
 * let arg1: CallArg = { Object: { Shared: {
 *   objectId: '5460cf92b5e3e7067aaace60d88324095fd22944',
 *   initialSharedVersion: 1,
 * } } };
 * let arg2: CallArg = { Pure: bcs.set(bcs.STRING, 100000).toBytes() };
 * let arg3: CallArg = { Object: { ImmOrOwned: {
 *   objectId: '4047d2e25211d87922b6650233bd0503a6734279',
 *   version: 1,
 *   digest: 'bCiANCht4O9MEUhuYjdRCqRPZjr2rJ8MfqNiwyhmRgA='
 * } } };
 * ```
 *
 * For `Pure` arguments BCS is required. You must encode the values with BCS according
 * to the type required by the called function. Pure accepts only serialized values
 */
public enum SuiCallArg{
    case Pure([UInt8])
    case Object(SuiObjectArg)
    case ObjVec([SuiObjectArg])
}
/**
 * Transaction type used for calling Move modules' functions.
 * Should be crafted carefully, because the order of type parameters and
 * arguments matters.
 */
/**
    MoveCallTx: {
      package: BCS.ADDRESS,
      module: BCS.STRING,
      function: BCS.STRING,
      typeArguments: 'vector<TypeTag>',
      arguments: 'vector<CallArg>',
    }
 */

public struct SuiMoveCallTx: SuiBSCTransactionObject{
    // 0.27
    public var package: SuiAddress
    public var module: String
    public var function: String
    public var typeArguments: [SuiTypeTag]
    public var arguments: [SuiCallArg]
    public init(package: SuiAddress, module: String, function: String, typeArguments: [SuiTypeTag], arguments: [SuiCallArg]) {
        self.package = package
        self.module = module
        self.function = function
        self.typeArguments = typeArguments
        self.arguments = arguments
    }
}

/**
 * Transaction type used for transferring objects.
 * For this transaction to be executed, and `SuiObjectRef` should be queried
 * upfront and used as a parameter.
 */

public struct SuiTransferObjectTx: SuiBSCTransactionObject{
    public var recipient: SuiAddress
    public var object_ref: SuiObjectRef
    public init(recipient: String, object_ref: SuiObjectRef) {
        self.recipient = try! SuiAddress(value: recipient)
        self.object_ref = object_ref
    }
}
/**
 * Transaction type used for transferring Sui.
 */

public struct SuiTransferSuiTx: SuiBSCTransactionObject{
    public var recipient: SuiAddress
    public var amount: UInt64?
    public init(recipient: String, amount: UInt64? = nil) {
        self.recipient = try! SuiAddress(value: recipient)
        self.amount = amount
    }
}

/**
 * Transaction type used for Pay transaction.
 */
/// Pay each recipient the corresponding amount using the input coins
public struct SuiPayTx: SuiBSCTransactionObject{
    /// The coins to be used for payment
    public var coins: [SuiObjectRef]
    /// The addresses that will receive payment
    public var recipients: [SuiAddress]
    /// The amounts each recipient will receive.
    /// Must be the same length as recipients
    public var amounts: [UInt64]
    public init(coins: [SuiObjectRef], recipients: [String], amounts: [UInt64]) {
        self.coins = coins
        self.recipients = recipients.map{try! SuiAddress(value: $0)}
        self.amounts = amounts
    }
}

/// Send SUI coins to a list of addresses, following a list of amounts.
/// only for SUI coin and does not require a separate gas coin object.
/// Specifically, what pay_sui does are:
/// 1. debit each input_coin to create new coin following the order of
/// amounts and assign it to the corresponding recipient.
/// 2. accumulate all residual SUI from input coins left and deposit all SUI to the first
/// input coin, then use the first input coin as the gas coin object.
/// 3. the balance of the first input coin after tx is sum(input_coins) - sum(amounts) - actual_gas_cost
/// 4. all other input coints other than the first one are deleted.
///
public struct SuiPaySuiTx: SuiBSCTransactionObject{
    /// The coins to be used for payment.
    public var coins: [SuiObjectRef]
    /// The addresses that will receive payment
    public var recipients: [SuiAddress]
    /// The amounts each recipient will receive.
    /// Must be the same length as recipients
    public var amounts: [UInt64]
    public init(coins: [SuiObjectRef], recipients: [String], amounts: [UInt64]) {
        self.coins = coins
        self.recipients = recipients.map{try! SuiAddress(value: $0)}
        self.amounts = amounts
    }
}

/// Send all SUI coins to one recipient.
/// only for SUI coin and does not require a separate gas coin object either.
/// Specifically, what pay_all_sui does are:
/// 1. accumulate all SUI from input coins and deposit all SUI to the first input coin
/// 2. transfer the updated first coin to the recipient and also use this first coin as
/// gas coin object.
/// 3. the balance of the first input coin after tx is sum(input_coins) - actual_gas_cost.
/// 4. all other input coins other than the first are deleted.
///
///
public struct SuiPayAllSuiTx: SuiBSCTransactionObject{
    /// The coins to be used for payment.
    public var coins: [SuiObjectRef]
    /// The address that will receive payment
    public var recipient: SuiAddress
    public init(coins: [SuiObjectRef], recipient: String) {
        self.coins = coins
        self.recipient = try! SuiAddress(value: recipient)
    }
}
/**
 * Transaction type used for publishing Move modules to the Sui.
 * Should be already compiled using `sui-move`, example:
 * ```
 * $ sui-move build
 * $ cat build/project_name/bytecode_modules/module.mv
 * ```
 * In JS:
 * ```
 * let file = fs.readFileSync('./move/build/project_name/bytecode_modules/module.mv');
 * let bytes = Array.from(bytes);
 * let modules = [ bytes ];
 *
 * // ... publish logic ...
 * ```
 *
 * Each module should be represented as a sequence of bytes.
 */
public struct SuiPublishTx: SuiBSCTransactionObject{
    public var modules: [[UInt8]]
    public init(modules: [[UInt8]]) {
        self.modules = modules
    }
}
// ========== TransactionData ===========

public enum SuiTransaction{
    /// Initiate an object transfer between addresses
    case TransferObjectTx(SuiTransferObjectTx)
    /// Publish a new Move module
    case PublishTx(SuiPublishTx)
    /// Call a function in a published Move module
    case MoveCallTx(SuiMoveCallTx)
    /// Initiate a SUI coin transfer between addresses
    case TransferSuiTx(SuiTransferSuiTx)
    /// Pay multiple recipients using multiple input coins
    case PayTx(SuiPayTx)
    /// Pay multiple recipients using multiple SUI coins,
    /// no extra gas payment SUI coin is required.
    case PaySuiTx(SuiPaySuiTx)
    /// After paying the gas of the transaction itself, pay
    /// pay all remaining coins to the recipient.
    case PayAllSuiTx(SuiPayAllSuiTx)
}

// TODO: Make SingleTransactionKind a Box
public enum SuiTransactionKind{
    /// A single transaction.
    case Single(SuiTransaction)
    /// A batch of single transactions.
    case Batch([SuiTransaction])
    // .. more transaction types go here
}

/**
 * The GasData to be used in the transaction.     (0.27 add)
 */
public struct SuiGasData{
    var payment: SuiObjectRef
    var owner: SuiAddress
    // https://github.com/MystenLabs/sui/blob/f32877f2e40d35a008710c232e49b57aab886462/crates/sui-types/src/messages.rs#L338
    var price: UInt64
    var budget: UInt64
    init(payment: SuiObjectRef, owner: SuiAddress, price: UInt64 = 1, budget: UInt64 = 10000) {
        self.payment = payment
        self.owner = owner
        self.price = price
        self.budget = budget
    }
}
/**
 * TransactionExpiration
 *
 * Indications the expiration time for a transaction.
 */
public enum SuiTransactionExpiration{
    case None
    case Epoch(UInt64)
}
/**
 * The TransactionData to be signed and sent to the RPC service.
 *
 * Field `sender` is made optional as it can be added during the signing
 * process and there's no need to define it sooner.
 */

public struct SuiTransactionData{
    // TODO: support batch txns
    public var kind: SuiTransactionKind
    public var sender: SuiAddress
    public var gasData: SuiGasData
    public var expiration: SuiTransactionExpiration
    init(kind: SuiTransactionKind, sender: SuiAddress, gasData: SuiGasData, expiration: SuiTransactionExpiration = .None) {
        self.kind = kind
        self.sender = sender
        self.gasData = gasData
        self.expiration = expiration
    }
}
