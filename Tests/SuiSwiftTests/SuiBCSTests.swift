import XCTest
@testable import SuiSwift

final class SuiBCSTests: XCTestCase {
    func test_bcsTransaction() throws {
        let transaction = SuiProgrammableTransaction(inputs: try inputs(), transactions: try transactions())
        let kind = SuiTransactionKind.ProgrammableTransaction(transaction)
        let expiration = SuiTransactionExpiration.None
        let tx = SuiTransactionDataV1(kind: kind, sender: try SuiAddress(value: SuiAddress.normalizeSuiAddress(address: "0xBAD")), gasData: try gasData(), expiration: expiration)
        var txData = Data()
        try SuiTransactionData.V1(tx).serialize(to: &txData)
        XCTAssertTrue(txData.toHexString() == "000004010035580000000000000000000000000000000000000000000000000000000000009923000000000000140001020304050607080900010203040506070809001a03046e616d650b6465736372697074696f6e07696d675f75726c0042030b43617079207b6e616d657d16412063757465206c6974746c652063726561747572651d68747470733a2f2f6170692e636170792e6172742f7b69647d2f737667002035580000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000207646973706c6179036e65770107000000000000000000000000000000000000000000000000000000000000000204636170790443617079000101000000000000000000000000000000000000000000000000000000000000000000000207646973706c61790c6164645f6d756c7469706c650107000000000000000000000000000000000000000000000000000000000000000204636170790443617079000302000001010001020000000000000000000000000000000000000000000000000000000000000000000207646973706c61790e7570646174655f76657273696f6e0107000000000000000000000000000000000000000000000000000000000000000204636170790443617079000102000001010200000103000000000000000000000000000000000000000000000000000000000000000bad01355800000000000000000000000000000000000000000000000000000000000099230000000000001400010203040506070809000102030405060708090000000000000000000000000000000000000000000000000000000000000002010000000000000040420f000000000000")
    }
    func payments() -> [SuiObjectRef]{
        return [ref()]
    }
    
    func gasData() throws -> SuiGasData{
        let owner = try SuiAddress(value: SuiAddress.normalizeSuiAddress(address: "0x2"))
        return SuiGasData(payment: payments(), owner: owner, price: 1, budget: 1000000)
    }
    // inputs
    func inputs() throws -> [SuiCallArg]{
        var inputs = [SuiCallArg]()
        inputs.append(SuiCallArg.Object(.ImmOrOwned(ref())))
        let input1 = ["name", "description", "img_url"]
        var input1_data = Data()
        try input1.serialize(to: &input1_data)
        inputs.append(SuiCallArg.Pure(input1_data.bytes))
        
        let input2 = ["Capy {name}", "A cute little creature", "https://api.capy.art/{id}/svg"]
        var input2_data = Data()
        try input2.serialize(to: &input2_data)
        inputs.append(SuiCallArg.Pure(input2_data.bytes))
        
        let input3 = ref().objectId
        var input3_data = Data()
        try input3.serialize(to: &input3_data)
        inputs.append(SuiCallArg.Pure(input3_data.bytes))
        return inputs
    }
    // transactions
    func transactions() throws -> [SuiTransactionInner]{
        let owner = try SuiAddress(value: SuiAddress.normalizeSuiAddress(address: "0x2"))
        // transaction1
        let transaction1 = SuiMoveCallTransaction(target: owner.value + "::" + "display::new", typeArguments: [owner.value + "::" + "capy::Capy"], arguments: [.TransactionBlockInput(.init(index: 0))])
        
        // transaction2
        let transaction2 = SuiMoveCallTransaction(target: owner.value + "::" + "display::add_multiple", typeArguments: [owner.value + "::" + "capy::Capy"], arguments: [.Result(.init(index: 0)), .TransactionBlockInput(.init(index: 1)), .TransactionBlockInput(.init(index: 2))])
        
        // transaction3
        let transaction3 = SuiMoveCallTransaction(target: owner.value + "::" + "display::update_version", typeArguments: [owner.value + "::" + "capy::Capy"], arguments: [.Result(.init(index: 0))])
        
        // transaction4
        let transaction4 = SuiTransferObjectsTransaction(objects: [.Result(.init(index: 0))], address: .TransactionBlockInput(.init(index: 3)))
        return [.MoveCall(transaction1),
                .MoveCall(transaction2),
                .MoveCall(transaction3),
                .TransferObjects(transaction4)]
        
    }
    func ref() -> SuiObjectRef{
        return SuiObjectRef(digest: "1Bhh3pU9gLXZhoVxkr5wyg9sX6", objectId: "3558000000000000000000000000000000000000000000000000000000000000", version: 9113)
    }
}
