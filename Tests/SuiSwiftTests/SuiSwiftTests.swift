import XCTest
import CryptoSwift
@testable import SuiSwift

final class SuiSwiftTests: XCTestCase {
    func test_address() throws{
        let keypair = try SuiEd25519Keypair(mnemonics: "rose arch frozen pioneer mango spike ship say result runway daring spin")
        let publicKey = try SuiEd25519PublicKey(publicKey: keypair.publicData)
        XCTAssertTrue(try publicKey.toSuiAddress().value == "0xe2317a56ae0bd95ab6237161e4010cfbc67b66ba")
        print(try publicKey.toSuiAddress())
        
        print(try SuiEd25519Keypair.randomKeyPair().getPublicKey().toSuiAddress().value)
    }

    func test_transfer_sui_bcs() throws {
        let reqeustExpectation = expectation(description: "test_transfer_sui_bcs")
        DispatchQueue.global().async(.promise){
            let paySui = SuiPaySuiTransaction(
                inputCoins: ["0x870a64c64e69237f7f94970a011eae9f49fe0d61"],
                recipients: [SuiAddress(value: "0xe2317a56ae0bd95ab6237161e4010cfbc67b66ba")], amounts: [100000], gasBudget: 300)
            
            let transactionData = SuiTransactionData(sender: "0xe2317a56ae0bd95ab6237161e4010cfbc67b66ba",gasBudget: 300, kind: .Single(try paySui.bcsTransaction().wait()), gasPayment: SuiObjectRef(digest: "NqBSnJ2jJCcslFGclvDQndE3Aus1l7MQKAh4btxKez8=", objectId: "0x870a64c64e69237f7f94970a011eae9f49fe0d61", version: 4))
            var serializeTransactionData = Data()
            try transactionData.serialize(to: &serializeTransactionData)
            XCTAssertTrue(serializeTransactionData.encodeBase64Str()! == "VHJhbnNhY3Rpb25EYXRhOjoABQGHCmTGTmkjf3+UlwoBHq6fSf4NYQQAAAAAAAAAIDagUpydoyQnLJRRnJbw0J3RNwLrNZezECgIeG7cSns/AeIxelauC9latiNxYeQBDPvGe2a6AaCGAQAAAAAA4jF6Vq4L2Vq2I3Fh5AEM+8Z7ZrqHCmTGTmkjf3+UlwoBHq6fSf4NYQQAAAAAAAAAIDagUpydoyQnLJRRnJbw0J3RNwLrNZezECgIeG7cSns/AQAAAAAAAAAsAQAAAAAAAA==")
            reqeustExpectation.fulfill()
        }.catch { error in
            debugPrint(error)
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    func test_moveCall_nft_bcs() throws{
        let reqeustExpectation = expectation(description: "test_getNormalizedMoveStruct")
        DispatchQueue.global().async(.promise){
            let moveCall = SuiMoveCallTransaction(
                packageObjectId: "0x0000000000000000000000000000000000000002",
                module: "devnet_nft",
                function: "mint",
                typeArguments: .Strings([]),
                arguments: [.Str("Example NFT"),
                            .Str("An NFT created by Sui Wallet"),
                            .Str("ipfs://QmZPWWy5Si54R3d26toaqRiqvCH7HkGdXkxwUgCm2oKKM2?filename=img-sq-01.png")],
                gasBudget: 10000)
            
            let transactionData = SuiTransactionData(sender: "0xe2317a56ae0bd95ab6237161e4010cfbc67b66ba",gasBudget: moveCall.gasBudget, kind: .Single(try moveCall.bcsTransaction().wait()), gasPayment: SuiObjectRef(digest: "E4Lo1PInBkTV6FRFE5cULqO96k9jrpk3YcU+RNVhsDc=", objectId: "0x4328e8c6f13b658ead58145694f22d81b1876af3", version: 2))
            var serializeTransactionData = Data()
            try transactionData.serialize(to: &serializeTransactionData)
            
            XCTAssertTrue(serializeTransactionData.encodeBase64Str()! == "VHJhbnNhY3Rpb25EYXRhOjoAAgAAAAAAAAAAAAAAAAAAAAAAAAACAQAAAAAAAAAgrUd+yyNncmiOE+31Fz+w5YwHA+1hpiSfUqRnZJKhLN4KZGV2bmV0X25mdARtaW50AAMADAtFeGFtcGxlIE5GVAAdHEFuIE5GVCBjcmVhdGVkIGJ5IFN1aSBXYWxsZXQATUxpcGZzOi8vUW1aUFdXeTVTaTU0UjNkMjZ0b2FxUmlxdkNIN0hrR2RYa3h3VWdDbTJvS0tNMj9maWxlbmFtZT1pbWctc3EtMDEucG5n4jF6Vq4L2Vq2I3Fh5AEM+8Z7ZrpDKOjG8Ttljq1YFFaU8i2BsYdq8wIAAAAAAAAAIBOC6NTyJwZE1ehURROXFC6jvepPY66ZN2HFPkTVYbA3AQAAAAAAAAAQJwAAAAAAAA==")
            reqeustExpectation.fulfill()
            
        }.catch { error in
            debugPrint("error: \(error)")
            reqeustExpectation.fulfill()
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func test_decode_moveCall_nft_bcs() throws{
        let mintNftData = Array(base64: "VHJhbnNhY3Rpb25EYXRhOjoAAgAAAAAAAAAAAAAAAAAAAAAAAAACAQAAAAAAAAAgrUd+yyNncmiOE+31Fz+w5YwHA+1hpiSfUqRnZJKhLN4KZGV2bmV0X25mdARtaW50AAMADAtFeGFtcGxlIE5GVAAdHEFuIE5GVCBjcmVhdGVkIGJ5IFN1aSBXYWxsZXQATUxpcGZzOi8vUW1aUFdXeTVTaTU0UjNkMjZ0b2FxUmlxdkNIN0hrR2RYa3h3VWdDbTJvS0tNMj9maWxlbmFtZT1pbWctc3EtMDEucG5n4jF6Vq4L2Vq2I3Fh5AEM+8Z7ZrpDKOjG8Ttljq1YFFaU8i2BsYdq8wIAAAAAAAAAIBOC6NTyJwZE1ehURROXFC6jvepPY66ZN2HFPkTVYbA3AQAAAAAAAAAQJwAAAAAAAA==")
        var reader = BinaryReader(bytes: mintNftData)
        let mintTransaction = try SuiTransactionData(from: &reader)
        
        var serializeData = Data()
        try mintTransaction.serialize(to: &serializeData)
        
        XCTAssertTrue(serializeData.bytes == mintNftData)
    }
}
