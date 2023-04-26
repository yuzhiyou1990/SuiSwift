import XCTest
@testable import SuiSwift

final class SuiTransactionTests: XCTestCase {
    var client = SuiJsonRpcProvider()
    var builder = TransactionBlock(sender: try! SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"))
    var keypair = try! SuiEd25519Keypair(key: Data(hex: "0x7cc70de1e5c454bfc43b71d6da2b3cee1260caa7a5daf508cc1cdb95380a61de"))
   
    func test_transafer() throws{
        let reqeustExpectation = expectation(description: "test_transafer")
        DispatchQueue.global().async {
            do {
                let gas = try self.client.getGasObjectsOwnedByAddress(address: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27").wait()[0]
                //gas
                self.builder.setPatment(payment: [gas.getObjectReference()!])
                //split
                let coin = self.builder.splitCoins(transaction: .init(coin: self.builder.gas, amounts: [try self.builder.setPure(value: UInt64(100))]))
                // recipient
                self.builder.transferObjects(transaction: .init(objects: [coin], address: try self.builder.setPure(value: SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"))))
                
                let data = try self.builder.build(provider: self.client).wait()
                let block = try data.signTxnBytesWithKeypair(keypair: self.keypair)
                let tx = try self.client.executeTransactionBlock(model: block).wait()
                debugPrint("success \(tx.digest.value)")
                reqeustExpectation.fulfill()
            } catch let error {
                debugPrint(error)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
}
