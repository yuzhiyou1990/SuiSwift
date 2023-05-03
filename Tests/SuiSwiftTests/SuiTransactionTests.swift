import XCTest
import BigInt
import PromiseKit
@testable import SuiSwift

final class SuiTransactionTests: XCTestCase {
    var provider = SuiJsonRpcProvider()
    var builder = SuiTransaction(sender: try! SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"))
    var keypair = try! SuiEd25519Keypair(key: Data(hex: "0x7cc70de1e5c454bfc43b71d6da2b3cee1260caa7a5daf508cc1cdb95380a61de"))
   
    func test_transafer() throws{
        let reqeustExpectation = expectation(description: "test_transafer")
        DispatchQueue.global().async {
            do {
                let gas = try self.provider.getGasObjectsOwnedByAddress(address: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27").wait()[0]
                //gas
                self.builder.setPatment(payment: [gas.getObjectReference()!])
                //split
                let coin = self.builder.splitCoins(transaction: .init(coin: self.builder.gas, amounts: [try self.builder.setPure(value: UInt64(100))]))
                // recipient
                self.builder.transferObjects(transaction: .init(objects: [coin], address: try self.builder.setPure(value: SuiAddress(value: "0x936accb491f0facaac668baaedcf4d0cfc6da1120b66f77fa6a43af718669973"))))
                
                let data = try self.builder.build(provider: self.provider).wait()
                let block = try data.signTxnBytesWithKeypair(keypair: self.keypair)
                let tx: SuiTransactionBlockResponse = try self.provider.executeTransactionBlock(model: block).wait()
                debugPrint("success \(tx.digest.value)")
                reqeustExpectation.fulfill()
            } catch let error {
                debugPrint(error)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_bcsCoinTransaction() throws {
        
        let reqeustExpectation = expectation(description: "test_transafer")
        DispatchQueue.global().async {
            do {
                let amount = BigUInt(40000000)
                let payments = try self.getPayments(address: try SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"), amount: amount, MAX_GAS_OBJECTS: 10).wait()
                let objectids = try self.getCoins(address: try SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"), amount: amount, coinType: "0x8147f6f60c22bf8b46c769206293f35319f9ef053641f77326376f11f505f39::flx::FLX").wait()
                let tx = try SuiTransaction.transactionCoin(from: try SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"), to: try SuiAddress(value: "0xd71c61a69a485e2fd44f5135c018ce8baa1e86dbc46199a699134bf4c9a71695"), amount: amount, gasPayment: payments, objectids: objectids)
                let data = try tx.build(provider: self.provider).wait()
                let signTx = try data.signTxnBytesWithKeypair(keypair: self.keypair)
                let txTransaction: SuiTransactionBlockResponse  = try self.provider.executeTransactionBlock(model: signTx).wait()
                debugPrint("success \(txTransaction.digest.value)")
                reqeustExpectation.fulfill()
                
            } catch let error {
                debugPrint(error)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
        
    }
    
    func getCoins(address: SuiAddress, amount: BigUInt, coinType: String) -> Promise<[SuiObjectRef]> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInitiated).async(.promise){
                var objectids = [SuiObjectRef]()
                var practical = BigUInt(0)
                var nextCursor: String?
                var hasNextPage: Bool = true
                while practical < amount && hasNextPage{
                    let requestRefs = SuiRequestCoins(owner: address, coinType: coinType, cursor: nextCursor)
                    let coins = try self.provider.getCoins(model: requestRefs).wait()
                    hasNextPage = coins.hasNextPage
                    nextCursor = coins.nextCursor
                    for coin in coins.data {
                        if practical >= amount{
                            break
                        }
                        practical = practical + (BigUInt(coin.balance) ?? 0)
                        objectids.append(SuiObjectRef(digest: coin.digest.value, objectId: coin.coinObjectId.value, version: coin.version.value()))
                    }
                }
                guard practical >= amount else{
                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("Asset.Send.Insufficient.Balance")
                }
                seal.fulfill(objectids)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    func getPayments(address: SuiAddress, amount: BigUInt, MAX_GAS_OBJECTS: UInt64 = 256) -> Promise<[SuiObjectRef]> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInitiated).async(.promise){
                let requestRefs = SuiRequestCoins(owner: address, coinType: SUI_TYPE_ARG, limit: MAX_GAS_OBJECTS)
                let coins = try self.provider.getCoins(model: requestRefs).wait()
                var payments = [SuiObjectRef]()
                var practical = BigUInt(0)
                for coin in coins.data {
                    if practical >= amount{
                        break
                    }
                    practical = practical + (BigUInt(coin.balance) ?? 0)
                    payments.append(SuiObjectRef(digest: coin.digest.value, objectId: coin.coinObjectId.value, version: coin.version.value()))
                }
                guard practical >= amount else{
                    throw SuiError.BuildTransactionError.ConstructTransactionDataError("Asset.Send.Insufficient.Balance")
                }
                seal.fulfill(payments)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
