//
//  SuiRPCTests.swift
//  
//
//  Created by li shuai on 2022/11/2.
//

import XCTest
import CryptoSwift
@testable import SuiSwift

final class SuiRPCTests: XCTestCase {
//    var client = SuiJsonRpcProvider(url: URL(string: "https://fullnode.testnet.sui.io/")!)
    var client = SuiJsonRpcProvider()
    var DEFAULT_PACKAGE = "0x2"
    var DEFAULT_MODULE = "coin"
    var DEFAULT_FUNCTION = "balance"
    var DEFAULT_STRUCT = "Coin"
    
    func test_getObjectsOwnedByAddress() throws{
        let reqeustExpectation = expectation(description: "getObjectsOwnedByAddress")
        
        self.client.getObjectsOwnedByAddress(address: "0xe2317a56ae0bd95ab6237161e4010cfbc67b66ba").done { infos in
           
            reqeustExpectation.fulfill()
        }.catch {error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getObjects() throws {
        
        let reqeustExpectation = expectation(description: "getObjects")
        self.client.getObjectBatch(objectIds: ["0x0000000000000000000000000000000000000005"]).done { objects in
            switch objects[0].details{
            case .SuiObject(let suiobject):
                print(suiobject.data.balance())
                break
            case .ObjectId( _):
                break
            case .SuiObjectRef( _):
                break
            }
            reqeustExpectation.fulfill()
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getCoinBalancesOwnedByAddress() throws {
        let reqeustExpectation = expectation(description: "getCoinBalancesOwnedByAddress")
        self.client.getCoinBalancesOwnedByAddress(address: "0xe2317a56ae0bd95ab6237161e4010cfbc67b66ba").done { responses in
            print(responses)
            reqeustExpectation.fulfill()
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_payTransaction() throws {
        let reqeustExpectation = expectation(description: "test_payTransaction")
        let signAddress = try SuiAddress(value: "0xe2317a56ae0bd95ab6237161e4010cfbc67b66ba")
        let keypair = try SuiEd25519Keypair(mnemonics: "rose arch frozen pioneer mango spike ship say result runway daring spin")
        self.client.getCoinBalancesOwnedByAddress(address: signAddress.value).done { responses in
            var objects = [SuiObjectId]()
            for dataResponse in responses{
                objects.append(dataResponse.getObjectId()!)
            }
            let pay = SuiPayTransaction(inputCoins: [objects[0],objects[1],objects[2],objects[3]], recipients: [signAddress], amounts: [123], gasBudget: 300)
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let transactionData = try self?.client.constructTransactionData(tx: pay, signerAddress: signAddress).wait()
                    var serializeTransactionData = Data()
                    try transactionData?.serialize(to: &serializeTransactionData)
                    
                    let signData = try keypair.signData(message: serializeTransactionData)
                    let publicKey = try keypair.getPublicKey().toBase64()
                    
                    self?.client.executeTransactionWithRequestType(txnBytes: serializeTransactionData.encodeBase64Str()!, signatureScheme: .ED25519, signature: signData.encodeBase64Str()!, pubkey: publicKey).done { response in
                        
                        debugPrint("response: \(response)")
                        reqeustExpectation.fulfill()
                    }.catch { error in
                        debugPrint("error: \(error)")
                        reqeustExpectation.fulfill()
                    }
                } catch let error {
                    debugPrint("error: \(error)")
                    reqeustExpectation.fulfill()
                }
            }
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 100)
    }
    
    //https://github.com/MystenLabs/sui/blob/1aca0465275496e40f02a674938def962126412b/sdk/typescript/src/types/transactions.ts
    func test_gasTotalUsed() throws {
        let reqeustExpectation = expectation(description: "test_gasCost")
        
        self.client.getEffects(txnBytes: "VHJhbnNhY3Rpb25EYXRhOjoABQGHCmTGTmkjf3+UlwoBHq6fSf4NYQQAAAAAAAAAIDagUpydoyQnLJRRnJbw0J3RNwLrNZezECgIeG7cSns/AeIxelauC9latiNxYeQBDPvGe2a6AaCGAQAAAAAA4jF6Vq4L2Vq2I3Fh5AEM+8Z7ZrqHCmTGTmkjf3+UlwoBHq6fSf4NYQQAAAAAAAAAIDagUpydoyQnLJRRnJbw0J3RNwLrNZezECgIeG7cSns/AQAAAAAAAAAsAQAAAAAAAA==").done { effects in
            debugPrint("GasUsed: \(effects.gasUsed.computationCost + effects.gasUsed.storageCost - effects.gasUsed.storageRebate)")
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 100)
    }
}
