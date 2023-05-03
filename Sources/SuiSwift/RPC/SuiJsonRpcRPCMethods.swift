//
//  SuiJsonRpcProvider+RPCMethods.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation
import PromiseKit
import BigInt
import AnyCodable

extension SuiJsonRpcProvider{
    public enum RPCMethod: String, Encodable{
        case GetObject = "sui_getObject"
        case RpcApiVersion = "rpc.discover"
        case GetMoveFunctionArgTypes = "sui_getMoveFunctionArgTypes"
        case GetNormalizedMoveModulesByPackage = "sui_getNormalizedMoveModulesByPackage"
        case GetNormalizedMoveModule = "sui_getNormalizedMoveModule"
        case GetNormalizedMoveFunction = "sui_getNormalizedMoveFunction"
        case GetNormalizedMoveStruct = "sui_getNormalizedMoveStruct"
        case GetCoins = "suix_getCoins"
        case GetAllCoins = "suix_getAllCoins"
        case GetBalance = "suix_getBalance"
        case GetAllBalances = "suix_getAllBalances"
        case GetCoinMetadata = "suix_getCoinMetadata"
        case GetOwnedObjects = "suix_getOwnedObjects"
        case MultiGetObjects = "sui_multiGetObjects"
        case ExecuteTransactionBlock = "sui_executeTransactionBlock"
        case GetTotalTransactionBlocks = "sui_getTotalTransactionBlocks"
        case GetReferenceGasPrice = "suix_getReferenceGasPrice"
        case GetStakes = "suix_getStakes"
        case GetStakesByIds = "suix_getStakesByIds"
        case GetLatestSuiSystemState = "suix_getLatestSuiSystemState"
        case DryRunTransactionBlock = "sui_dryRunTransactionBlock"
        case GetLatestCheckpointSequenceNumber = "sui_getLatestCheckpointSequenceNumber"
    }
    
    /**
       * Get all Coin<`coin_type`> objects owned by an address.
       */
    
    public func getCoins(model: SuiRequestCoins) -> Promise<SuiPaginatedCoins>{
        return  self.sendRequest(method: .GetCoins, params: model)
    }
    
    /**
       * Get all Coin objects owned by an address.
       */
    public func getAllCoins(model: SuiRequestCoins) -> Promise<SuiPaginatedCoins>{
        return  self.sendRequest(method: .GetAllCoins, params: model)
    }
    
    /**
       * Get the total coin balance for one coin type, owned by the address owner.
       */
    public func getBalance(model: SuiRequestBalance) -> Promise<SuiCoinBalance>{
        return  self.sendRequest(method: .GetBalance, params: model)
    }
    
    /**
       * Get the total coin balance for all coin type, owned by the address owner.
       */
    
    public func getAllBalance(model: SuiRequestBalance) -> Promise<[SuiCoinBalance]>{
        return  self.sendRequest(method: .GetAllBalances, params: model)
    }
    
    /**
       * Fetch CoinMetadata for a given coin type
       */
    public func getCoinMetadata(coinType: String = SUI_TYPE_ARG) -> Promise<SuiCoinMetadata>{
        return  self.sendRequest(method: .GetCoinMetadata, params: [coinType])
    }
    
    public func getGasObjectsOwnedByAddress(address: String, coinType: String = SUI_TYPE_ARG, options: SuiObjectDataOptions = SuiObjectDataOptions(showType: true, showContent: true, showBcs: true, showOwner: true)) -> Promise<[SuiObjectResponse]>{
        return Promise { seal in
            DispatchQueue.global().async(.promise) {
                let coins = try self.getOwnedObjects(model: SuiGetOwnedObjects(owner: try SuiAddress(value: address), objectResponseQuery: SuiObjectResponseQuery(filter: nil, options: options))).wait()
                seal.fulfill(coins.data.filter { response in
                    SuiCoin.isSUI(data: response)
                })
                
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    /**
       * Get all objects owned by an address
       */
    public func getOwnedObjects(model: SuiGetOwnedObjects) -> Promise<SuiPaginatedObjectsResponse>{
        return  self.sendRequest(method: .GetOwnedObjects, params: model)
    }

    /**
       * Get details about an object
       */
    public func getObject(model: SuiGetObject) -> Promise<SuiObjectResponse>{
        return  self.sendRequest(method: .GetObject, params: model)
    }
    
    /**
       * Batch get details about a list of objects. If any of the object ids are duplicates the call will fail
       */
    public func multiGetObjects(model: SuiMultiGetObjects) -> Promise<[SuiObjectResponse]>{
        return  self.sendRequest(method: .MultiGetObjects, params: model)
    }
    
    public func executeTransactionBlock(model: SuiExecuteTransactionBlock) -> Promise<SuiTransactionBlockResponse>{
        return  self.sendRequest(method: .ExecuteTransactionBlock, params: model)
    }
    
    public func executeTransactionBlock(model: SuiExecuteTransactionBlock) -> Promise<AnyCodable>{
        return  self.sendRequest(method: .ExecuteTransactionBlock, params: model)
    }
    
    public func getLatestCheckpointSequenceNumber() -> Promise<String> {
        return Promise { seal in
            let params = "[]".data(using: .utf8)!
            self.sendRequest(method: .GetLatestCheckpointSequenceNumber, params: params)
                .done { seal.fulfill($0) }
                .catch { seal.reject($0) }
        }
    }
    /**
       * Dry run a transaction block and return the result.
       */
    public func dryRunTransactionBlock(transactionBlock: Base64String) -> Promise<SuiDryRunTransactionBlockResponse>{
        return  self.sendRequest(method: .DryRunTransactionBlock, params: [transactionBlock.value])
    }
    
    /**
       * Get total number of transactions
       */
    public func getTotalTransactionBlocks() -> Promise<BigUInt> {
        return Promise { seal in
            let data = "[]".data(using: .utf8)!
            self.sendRequest(method: .GetTotalTransactionBlocks, params: data).done { (number: String) in
                seal.fulfill(BigUInt(stringLiteral: number))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    /**
       * Getting the reference gas price for the network
       */
    public func getReferenceGasPrice() -> Promise<BigUInt> {
        return Promise { seal in
            let data = "[]".data(using: .utf8)!
            self.sendRequest(method: .GetReferenceGasPrice, params: data).done { (gasprice: String) in
                seal.fulfill(BigUInt(stringLiteral: gasprice))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    /**
       * Return the delegated stakes for an address
       */
    public func getStakes(owner: SuiAddress) -> Promise<[SuiDelegatedStake]> {
        return  self.sendRequest(method: .GetStakes, params: [owner.value])
    }
    
    /**
       * Return the delegated stakes queried by id.
       */
    public func getStakesByIds(stakedSuiIds: [SuiObjectId]) -> Promise<[SuiDelegatedStake]> {
        return  self.sendRequest(method: .GetStakesByIds, params: [stakedSuiIds])
    }
    
    /**
       * Return the latest system state content.
       */
    public func getLatestSuiSystemState() -> Promise<SuiSystemStateSummary> {
        return Promise { seal in
            let data = "[]".data(using: .utf8)!
            self.sendRequest(method: .GetLatestSuiSystemState, params: data).done { state in
                seal.fulfill(state)
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
    
    public func getNormalizedMoveFunctionParams(target: String) -> Promise<[SuiMoveNormalizedType]> {
        return Promise { seal in
            DispatchQueue.global().async(.promise){
                let target = target.replacingOccurrences(of: " ", with: "")
                let words = target.components(separatedBy: "::")
                guard words.count == 3 else{
                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("moveModulesToResolve target parse error")
                }
                let pkg = words[0]
                let module = words[1]
                let fun = words[2]
                let normalized = try self.getNormalizedMoveFunction(packageId: pkg, moduleName: module, functionName: fun).wait()
                let hasTxContext = normalized.parameters.count > 0 && SuiMoveNormalizedType.isTxContext(param: normalized.parameters.last!)
                let params = hasTxContext ? Array(normalized.parameters[0..<(normalized.parameters.count - 1)]) : normalized.parameters
                seal.fulfill(params)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
