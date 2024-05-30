import XCTest
import BigInt

@testable import SuiSwift

final class SuiBCSTests: XCTestCase {
    func test_Make() throws{
        let value: UInt8 = 1
        try SuiMoveCallTransaction.getJsonValue(argument: NSNumber(1000))
    }
    func test_amount() throws{
        let base64 = "AAACAAgAypo7AAAAAAAg1xxhpppIXi/UT1E1wBjOi6oehtvEYZmmmRNL9MmnFpUCAgABAQAAAQECAAABAQA6ytrySLGemWJtSlBkI88HPUNVeI6C3it+mtmKz01tJwEciCH16516T0ATrsNebS5Mi+h2cgdaCew4NFcZiE3ISWg25AAAAAAAICiwUpfCExvnSZPA8XQN1/OsXWdwSzzd8YOtnlvwaa2yOsra8kixnplibUpQZCPPBz1DVXiOgt4rfprZis9NbSfoAwAAAAAAABCQLQAAAAAAAA=="
        var reader = BinaryReader(bytes: Array(base64: base64))
        let tx = try SuiTransactionData(from: &reader)
        print(tx)
    }
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
    
    
    
    func testDappParse() throws {
        let reqeustExpectation = expectation(description: #function)
        let byteArray: [UInt8] = [0, 225, 245, 5, 0, 0, 0, 0]
        if let utf8String = String(bytes: byteArray, encoding: .utf8) {
            print(utf8String)
        } else {
            print("Cannot convert to UTF-8 string.")
        }
        let json = """
        {
            "version": 1,
            "sender": "0xca5b67735321f0fd05554f376cc600af5feba667a6dbb5fc4418b913a4a63fcd",
            "expiration": {
                "None": true
            },
            "gasConfig": {
                "payment": [{
                    "objectId": "0x036a9f9710bb943c31d420358bcc0914261edab7676316dde21f3de4b913ea72",
                    "version": "104316883",
                    "digest": "7zN952zzdkxPmEq7mm4sdESMGhM1cnctV2qr1y2Qf5xR"
                }],
                "owner": "0xca5b67735321f0fd05554f376cc600af5feba667a6dbb5fc4418b913a4a63fcd",
                "price": "751",
                "budget": "2584088"
            },
            "inputs": [{
                "kind": "Input",
                "value": {
                    "Pure": [0, 202, 154, 59, 0, 0, 0, 0]
                },
                "index": 0,
                "type": "pure"
            }, {
                "kind": "Input",
                "value": {
                    "Object": {
                        "ImmOrOwned": {
                            "objectId": "0x33353f2bcbd6aaaf86e54235e99f9c1211a3faeb78eb25c8f2c9c8f8badd7259",
                            "version": "104316883",
                            "digest": "73ohmqM8K5T5Z9BBTzXqKrByKq3HpHi13JtwHW5kd5H9"
                        }
                    }
                },
                "index": 1,
                "type": "object"
            }, {
                "kind": "Input",
                "value": {
                    "Object": {
                        "Shared": {
                            "objectId": "0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f",
                            "initialSharedVersion": "1574190",
                            "mutable": false
                        }
                    }
                },
                "index": 2,
                "type": "object"
            }, {
                "kind": "Input",
                "value": {
                    "Object": {
                        "Shared": {
                            "objectId": "0x2e041f3fd93646dcc877f783c1f2b7fa62d30271bdef1f21ef002cebf857bded",
                            "initialSharedVersion": "1964496",
                            "mutable": true
                        }
                    }
                },
                "index": 3,
                "type": "object"
            }, {
                "kind": "Input",
                "value": {
                    "Pure": [0]
                },
                "index": 4,
                "type": "pure"
            }, {
                "kind": "Input",
                "value": {
                    "Pure": [1]
                },
                "index": 5,
                "type": "pure"
            }, {
                "kind": "Input",
                "value": {
                    "Pure": [0, 202, 154, 59, 0, 0, 0, 0]
                },
                "index": 6,
                "type": "pure"
            }, {
                "kind": "Input",
                "value": {
                    "Pure": [175, 51, 27, 168, 50, 127, 187, 53, 177, 196, 254, 255, 0, 0, 0, 0]
                },
                "index": 7,
                "type": "pure"
            }, {
                "kind": "Input",
                "value": {
                    "Pure": [0]
                },
                "index": 8,
                "type": "pure"
            }, {
                "kind": "Input",
                "value": {
                    "Object": {
                        "Shared": {
                            "objectId": "0x0000000000000000000000000000000000000000000000000000000000000006",
                            "initialSharedVersion": "1",
                            "mutable": false
                        }
                    }
                },
                "index": 9,
                "type": "object"
            }, {
                "kind": "Input",
                "value": {
                    "Pure": [9, 88, 145, 128, 2, 0, 0, 0]
                },
                "index": 10,
                "type": "pure"
            }],
            "transactions": [{
                "kind": "SplitCoins",
                "coin": {
                    "kind": "GasCoin"
                },
                "amounts": [{
                    "kind": "Input",
                    "index": 0
                }]
            }, {
                "kind": "MoveCall",
                "target": "0x0000000000000000000000000000000000000000000000000000000000000002::coin::zero",
                "arguments": [],
                "typeArguments": ["0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS"]
            }, {
                "kind": "MoveCall",
                "target": "0x6f5e582ede61fe5395b50c4a449ec11479a54d7ff8e0158247adfda60d98970b::router::swap",
                "arguments": [{
                    "kind": "Input",
                    "index": 2
                }, {
                    "kind": "Input",
                    "index": 3
                }, {
                    "kind": "Result",
                    "index": 1
                }, {
                    "kind": "Result",
                    "index": 0
                }, {
                    "kind": "Input",
                    "index": 4
                }, {
                    "kind": "Input",
                    "index": 5
                }, {
                    "kind": "Input",
                    "index": 6
                }, {
                    "kind": "Input",
                    "index": 7
                }, {
                    "kind": "Input",
                    "index": 8
                }, {
                    "kind": "Input",
                    "index": 9
                }],
                "typeArguments": ["0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS", "0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI"]
            }, {
                "kind": "MoveCall",
                "target": "0x6f5e582ede61fe5395b50c4a449ec11479a54d7ff8e0158247adfda60d98970b::router::check_coin_threshold",
                "arguments": [{
                    "kind": "NestedResult",
                    "index": 2,
                    "resultIndex": 0
                }, {
                    "kind": "Input",
                    "index": 10
                }],
                "typeArguments": ["0x06864a6f921804860930db6ddbe2e16acdf8504495ea7481637a1c8b9a8fe54b::cetus::CETUS"]
            }, {
                "kind": "MergeCoins",
                "destination": {
                    "kind": "Input",
                    "index": 1
                },
                "sources": [{
                    "kind": "NestedResult",
                    "index": 2,
                    "resultIndex": 0
                }]
            }, {
                "kind": "MergeCoins",
                "destination": {
                    "kind": "GasCoin"
                },
                "sources": [{
                    "kind": "NestedResult",
                    "index": 2,
                    "resultIndex": 1
                }]
            }]
        }
        """
        guard let jsonData = json.data(using: .utf8) else {
            print("Failed to convert string to data.")
            return
        }
        let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        DispatchQueue.global().async {
            do{
                let suiTransactionBuilder = try SuiTransactionBuilder.ParseDAppTransaction(dic: dictionary ?? [:])
                _ = try suiTransactionBuilder.prepare(provider: .init(url: URL(string: "https://wallet-rpc.mainnet.sui.io")!)).wait()
                let buildData = try suiTransactionBuilder.build()
                debugPrint(suiTransactionBuilder)
                reqeustExpectation.fulfill()
            } catch {
                debugPrint(error.localizedDescription)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
}
