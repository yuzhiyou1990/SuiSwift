import XCTest
import CryptoSwift

@testable import SuiSwift

final class SuiKeypairTests: XCTestCase {
    func test_seck256() throws {
        let keypair = try SuiSecp256k1Keypair(mnemonics: "film crazy soon outside stand loop subway crumble thrive popular green nuclear struggle pistol arm wife phrase warfare march wheat nephew ask sunny firm", derivationPath: .DERVIATION_PATH_PURPOSE_SECP256K1(address_index: "0") )
        let address = try keypair.getPublicKey().toSuiAddress().value
        XCTAssertTrue(address == "0x9e8f732575cc5386f8df3c784cd3ed1b53ce538da79926b2ad54dcc1197d2532")
        
        let VALID_SECP256K1_SECRET_KEY: [UInt8] = [
            59, 148, 11, 85, 134, 130, 61, 253, 2, 174, 59, 70, 27, 180, 51, 107, 94, 203,
            174, 253, 102, 39, 170, 146, 46, 252, 4, 143, 236, 12, 136, 28,
          ]
        let keypair1 = try SuiSecp256k1Keypair(secretKey: Data(Array(VALID_SECP256K1_SECRET_KEY)))
        XCTAssertTrue(try keypair1.getPublicKey().publicKey == Data(Array([2, 29, 21, 35, 7, 198, 183, 43, 14, 208, 65, 139, 14, 112, 205, 128, 231, 245, 41, 91, 141, 134, 245, 114, 45, 63, 82, 19, 251, 210, 57, 79, 54])))
        let messageData = "Hello, world!".data(using: .utf8)!
        let signData = try keypair1.signData(message: messageData)
        print(signData.toHexString())
        XCTAssertTrue("25d450f191f6d844bf5760c5c7b94bc67acc88be76398129d7f43abdef32dc7f7f1a65b7d65991347650f3dd3fa3b3a7f9892a0608521cbcf811ded433b31f8b" == signData.toHexString())
    }
}
