import XCTest
import BigInt

@testable import SuiSwift

final class SuiRPCS: XCTestCase {
    var client = SuiJsonRpcProvider()

    func test_getcoins() throws {
        let reqeustExpectation = expectation(description: #function)
        
        self.client.getCoins(model: try! SuiRequestCoins(owner: SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"))).done { coins in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getAllcoins() throws {
        let reqeustExpectation = expectation(description: #function)
        
        self.client.getAllCoins(model: try! SuiRequestCoins(owner: SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"), coinType: nil)).done { coins in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getBalance() throws {
        let reqeustExpectation = expectation(description: #function)
        
        self.client.getBalance(model: try! SuiRequestBalance(owner: SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"))).done { balance in
            print(BigInt(balance.totalBalance)?.description)
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getAllBalance() throws {
        let reqeustExpectation = expectation(description: #function)
        
        self.client.getAllBalance(model: try! SuiRequestBalance(owner: SuiAddress(value: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"), coinType: nil)).done { balances in
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getCoinMetadata() throws {
        let reqeustExpectation = expectation(description: #function)
        
        self.client.getCoinMetadata().done { metadata in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getObject() throws {
        let reqeustExpectation = expectation(description: #function)
        
        self.client.getObject(model: SuiGetObject(id: "0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27")).done { response in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_multiGetObjects() throws {
        let reqeustExpectation = expectation(description: #function)
        
        self.client.multiGetObjects(model: SuiMultiGetObjects(ids: ["0x3acadaf248b19e99626d4a506423cf073d4355788e82de2b7e9ad98acf4d6d27"])).done { response in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getTotalTransactionBlocks() throws {
        let reqeustExpectation = expectation(description: #function)
        self.client.getTotalTransactionBlocks().done { reslut in
            reqeustExpectation.fulfill()
        }.cauterize()
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getLatestSuiSystemState() throws {
        let reqeustExpectation = expectation(description: #function)
        self.client.getLatestSuiSystemState().done { reslut in
            reqeustExpectation.fulfill()
        }.cauterize()
        wait(for: [reqeustExpectation], timeout: 30)
    }
}
