import XCTest
@testable import SuiSwift

final class SuiMoveCallTests: XCTestCase {
    var client = SuiJsonRpcProvider()
    var DEFAULT_PACKAGE = "0x2"
    var DEFAULT_MODULE = "coin"
    var DEFAULT_FUNCTION = "balance"
    var DEFAULT_STRUCT = "Coin"
    
    func test_getMoveFunctionArgTypes() throws {
        let reqeustExpectation = expectation(description: "test_getMoveFunctionArgTypes")
        DispatchQueue.global().async(.promise) {
            return try self.client.getCoinMetadata().wait()
        }.done { metadata in
            debugPrint("metadata: \(metadata)")
        }
        self.client.getMoveFunctionArgTypes(packageId: DEFAULT_PACKAGE, moduleName: DEFAULT_MODULE, functionName: DEFAULT_FUNCTION).done { atgTypes in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getNormalizedMoveModulesByPackage() throws {
        let reqeustExpectation = expectation(description: "test_getNormalizedMoveModulesByPackage")
        
        self.client.getNormalizedMoveModulesByPackage(packageId: DEFAULT_PACKAGE).done { modules in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getNormalizedMoveModule() throws {
        let reqeustExpectation = expectation(description: "test_test_getNormalizedMoveModule")
        
        self.client.getNormalizedMoveModule(packageId: DEFAULT_PACKAGE, moduleName: DEFAULT_MODULE).done { module in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getNormalizedMoveFunction() throws {
        let reqeustExpectation = expectation(description: "test_getNormalizedMoveFunction")
        
        self.client.getNormalizedMoveFunction(packageId: DEFAULT_PACKAGE, moduleName: DEFAULT_MODULE, functionName: DEFAULT_FUNCTION).done { function in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_getNormalizedMoveStruct() throws {
        let reqeustExpectation = expectation(description: "test_getNormalizedMoveStruct")
        
        self.client.getNormalizedMoveStruct(packageId: DEFAULT_PACKAGE, moduleName: DEFAULT_MODULE, structName: DEFAULT_STRUCT).done { `struct` in
            
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
}
