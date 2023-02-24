//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/2.
//

import Foundation
import PromiseKit
import BigInt

extension SuiJsonRpcProvider{
    public enum RPCMethod: String, Encodable{
        case GetObjectsOwnedByAddress = "sui_getObjectsOwnedByAddress"
        case GetObject = "sui_getObject"
        case RpcApiVersion = "rpc.discover"
        case GetSuiSystemState = "sui_getSuiSystemState"
        //version?.minor < 18
        case ExecuteTransaction = "sui_executeTransaction"
        //0.19.0
        case ExecuteTransactionSerializedSig = "sui_executeTransactionSerializedSig"
        case DryRunTransaction = "sui_dryRunTransaction"
        case GetMoveFunctionArgTypes = "sui_getMoveFunctionArgTypes"
        case GetNormalizedMoveModulesByPackage = "sui_getNormalizedMoveModulesByPackage"
        case GetNormalizedMoveModule = "sui_getNormalizedMoveModule"
        case GetNormalizedMoveFunction = "sui_getNormalizedMoveFunction"
        case GetNormalizedMoveStruct = "sui_getNormalizedMoveStruct"
    }
    
    public func getSuiSystemState() -> Promise<SuiSystemState> {
        return  self.sendRequest(method: .GetSuiSystemState, params: try! JSONSerialization.data(withJSONObject: [], options: []))
    }
    /**
       * Returns the estimated gas cost for the transaction
       * @param tx The transaction to estimate the gas cost. When string it is assumed it's a serialized tx in base64
       * @returns total gas cost estimation
       * @throws whens fails to estimate the gas cost
       */
    public func getEffects(txnBytes: String) -> Promise<SuiTransactionEffects> {
        return  self.sendRequest(method: .DryRunTransaction, params: [txnBytes])
    }
    
    /**
       * Convenience method for getting all coins objects owned by an address
       * @param typeArg optional argument for filter by coin type, e.g., '0x2::sui::SUI'
    */
    public func getCoinBalancesOwnedByAddress(address: String, typeArg: String? = SUI_TYPE_ARG) -> Promise<[SuiGetObjectDataResponse]>{
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                try self.getObjectsOwnedByAddress(address: address).wait()
            }.then { (infos) -> Promise<[SuiGetObjectDataResponse]> in
                let objects = infos.filter { info in
                    SuiCoin.isCoin(data: info) && (typeArg == nil || typeArg == SuiCoin.getCoinTypeArg(data: info))
                }
                let coinIds = objects.map{$0.objectId}
                return  self.getObjectBatch(objectIds: coinIds.map{$0.value})
            }.done { getObjectDataResponses in
                seal.fulfill(getObjectDataResponses)
            }.catch { error in
                seal.reject(SuiError.RPCError.ApiResponseError(method: #function, message: "Error fetching \(error)"))
            }
        }
    }
    
    // Objects
      /**
       * Get all objects owned by an address
       */
    public func getObjectsOwnedByAddress(address: String) -> Promise<[SuiObjectInfo]>{
        return  self.sendRequest(method: .GetObjectsOwnedByAddress, params: [address])
    }
    
    /**
       * Get details about an object
       */
    public func getObject(objectId: String) -> Promise<SuiGetObjectDataResponse>{
        return  self.sendRequest(method: .GetObject, params: [objectId])
    }
    
    /**
      * Get object reference(id, tx digest, version id)
      * @param objectId
      */
    public func getObjectRef(objectId: String) -> Promise<SuiObjectRef?>{
        return Promise { seal in
            DispatchQueue.global().async(.promise){ () -> SuiGetObjectDataResponse in
                try self.getObject(objectId: objectId).wait()
            }.done { objectData in
                seal.fulfill(objectData.getObjectReference())
            }.catch { error in
                seal.reject(SuiError.RPCError.ApiResponseError(method: #function, message: "Error fetching \(error)"))
            }
        }
    }
    public func getObjectBatch(objectIds: [String]) -> Promise<[SuiGetObjectDataResponse]>{
        let params = objectIds.map{(RPCMethod.GetObject, [$0])}
        return  self.sendBatchRequest(params: params)
    }
    // new version
    public func executeExecuteTransactionSerializedSigWithRequestType(signedTransaction: SuiSignedTransaction, requestType: SuiExecuteTransactionRequestType = .WaitForLocalExecution) -> Promise<SuiExecuteTransactionResponse>{
        var serialized_sig = [UInt8]()
        serialized_sig.append(signedTransaction.signatureScheme.rawValue)
        serialized_sig.append(contentsOf: Array(base64: signedTransaction.signature))
        serialized_sig.append(contentsOf: Array(base64: signedTransaction.pubkey))
        return self.sendRequest(method: .ExecuteTransactionSerializedSig, params: [signedTransaction.txnBytes, serialized_sig.toBase64(), requestType.rawValue])
    }
    
    public func executeExecuteTransactionWithRequestType(signedTransaction: SuiSignedTransaction, requestType: SuiExecuteTransactionRequestType = .WaitForLocalExecution) -> Promise<String>{
        var serialized_sig = [UInt8]()
        serialized_sig.append(signedTransaction.signatureScheme.rawValue)
        serialized_sig.append(contentsOf: Array(base64: signedTransaction.signature))
        serialized_sig.append(contentsOf: Array(base64: signedTransaction.pubkey))
        return self.sendRequest(method: .ExecuteTransactionSerializedSig, params: [signedTransaction.txnBytes, serialized_sig.toBase64(), requestType.rawValue])
    }
    
    /**
       * This is under development endpoint on Fullnode that will eventually
       * replace the other `executeTransaction` that's only available on the
     * Gateway_
    */
    public func executeTransactionWithRequestType(txnBytes: String, signatureScheme: SuiSignatureScheme, signature: String, pubkey: String, requestType: SuiExecuteTransactionRequestType = .WaitForTxCert) -> Promise<SuiExecuteTransactionResponse> {
        return self.sendRequest(method: .ExecuteTransaction, params: [txnBytes, signatureScheme.name(), signature, pubkey, requestType.rawValue])
    }
    
    /**
      * Convenience method for select coin objects that has a balance greater than or equal to `amount`
      *
      * @param amount coin balance
      * @param typeArg coin type, e.g., '0x2::sui::SUI'
      * @param exclude object ids of the coins to exclude
      * @return a list of coin objects that has balance greater than `amount` in an ascending order
    */
    public func selectCoinsWithBalanceGreaterThanOrEqual(address: String, amount: BigInt, typeArg: String = SUI_TYPE_ARG, exclude: [SuiObjectId] = []) -> Promise<[SuiGetObjectDataResponse]>{
        return Promise { seal in
            DispatchQueue.global().async(.promise){ () -> [SuiGetObjectDataResponse] in
                try self.getCoinBalancesOwnedByAddress(address: address, typeArg: typeArg).wait()
            }.done { coins in
                seal.fulfill(SuiCoin.selectCoinsWithBalanceGreaterThanOrEqual(coins: coins, amount: amount, exclude: exclude))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    // Move info
    /**
       * Get Move function argument types like read, write and full access
       */
    public func getMoveFunctionArgTypes(packageId: String, moduleName: String, functionName: String) -> Promise<SuiMoveFunctionArgTypes> {
        return Promise { seal in
            self.sendRequest(method: .GetMoveFunctionArgTypes, params: [packageId, moduleName, functionName]).done { (argTypes: SuiMoveFunctionArgTypes)  in
                seal.fulfill(argTypes)
            }.catch { error in
                seal.reject(SuiError.RPCError.ApiResponseError(method: #function, message: "Error fetching \(error) for package object ID: \(packageId), module name: \(moduleName), function name: \(functionName)"))
            }
        }
    }
    /**
       * Get a map from module name to
       * structured representations of Move modules
       */
    public func getNormalizedMoveModulesByPackage(packageId: String) -> Promise<SuiMoveNormalizedModules> {
        return Promise { seal in
            self.sendRequest(method: .GetNormalizedMoveModulesByPackage, params: [packageId]).done { (modules: SuiMoveNormalizedModules)  in
                seal.fulfill(modules)
            }.catch { error in
                seal.reject(SuiError.RPCError.ApiResponseError(method: #function, message: "Error fetching \(error) for package: \(packageId)"))
            }
        }
    }
    /**
       * Get a structured representation of Move module
       */
    public func getNormalizedMoveModule(packageId: String, moduleName: String) -> Promise<SuiMoveNormalizedModule> {
        return Promise { seal in
            self.sendRequest(method: .GetNormalizedMoveModule, params: [packageId, moduleName]).done { (module: SuiMoveNormalizedModule)  in
                seal.fulfill(module)
            }.catch { error in
                seal.reject(SuiError.RPCError.ApiResponseError(method: #function, message: "Error fetching module: \(error) for package \(packageId), module \(moduleName)"))
            }
        }
    }
    /**
       * Get a structured representation of Move function
       */
    public func getNormalizedMoveFunction(packageId: String, moduleName: String, functionName: String) -> Promise<SuiMoveNormalizedFunction> {
        return Promise { seal in
            self.sendRequest(method: .GetNormalizedMoveFunction, params: [packageId, moduleName, functionName]).done { (function: SuiMoveNormalizedFunction)  in
                seal.fulfill(function)
            }.catch { error in
                seal.reject(SuiError.RPCError.ApiResponseError(method: #function, message: "Error fetching function: \(error) for package \(packageId), module \(moduleName) and function \(functionName)"))
            }
        }
    }
    /**
      * Get a structured representation of Move struct
      */
    public func getNormalizedMoveStruct(packageId: String, moduleName: String, structName: String) -> Promise<SuiMoveNormalizedStruct> {
        return Promise { seal in
            self.sendRequest(method: .GetNormalizedMoveStruct, params: [packageId, moduleName, structName]).done { (`struct`: SuiMoveNormalizedStruct)  in
                seal.fulfill(`struct`)
            }.catch { error in
                seal.reject(SuiError.RPCError.ApiResponseError(method: #function, message: "Error fetching function: \(error) for package \(packageId), module \(moduleName) and structName \(structName)"))
            }
        }
    }
}
