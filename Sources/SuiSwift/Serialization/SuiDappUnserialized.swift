//
//  File.swift
//
//
//  Created by li shuai on 2023/3/1.
//
import Foundation

extension SuiError{
   public enum DappError: LocalizedError {
        case DappParseError
        case InvalidTransactionType
        case InvalidProvider
        case InvalidTransactionData
        case OtherEror(String)
        public var errorDescription: String?{
            switch self{
            case .DappParseError:
                return "SuiTransactionInput Parse Error"
            case .InvalidTransactionType:
                return "Invalid Transaction Type"
            case .InvalidProvider:
                return "Invalid Provider"
            case .InvalidTransactionData:
                return "Invalid TransactionData"
            case .OtherEror(let message):
                return message
            }
        }
       public var value: String{
            return self.localizedDescription
        }
    }
}

public protocol SuiDappUnserializedSignableTransaction: SuiUnserializedSignableTransaction{
    init(dic: Dictionary<String, AnyObject>) throws
}
extension SuiMergeCoinTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let primaryCoin = dic["primaryCoin"] as? String,
              let coinToMerge = dic["coinToMerge"] as? String,
              let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse MergeCoinTransaction Error")
        }
        let gasPayment = dic["gasPayment"] as? String
        let gasPrice = dic["gasPrice"] as? UInt64
        self.init(primaryCoin: primaryCoin, coinToMerge: coinToMerge, gasPayment: gasPayment, gasBudget: gasBudget, gasPrice: gasPrice)
    }
}
extension SuiTypeTag{
    /**
     * Sui TypeTag object. A decoupled `0x...::module::Type<???>` parameter.
     */
    static func typeTagWithTypeKey(key: String, value: AnyObject) -> SuiTypeTag?{
        switch key{
        case "bool":
            return .Bool
        case "u8":
            return .UInt8
        case "u16":
            return .UInt16
        case "u32":
            return .UInt32
        case "u64":
            return .UInt64
        case "u128":
            return .UInt128
        case "u256":
            return .UInt256
        case "address":
            return .Address
        case "signer":
            return .Signer
        case "vector":
            if let vector_map = value as? Dictionary<String, AnyObject>,
               let typeTag_map = vector_map.first{
                return typeTagWithTypeKey(key: typeTag_map.key, value: typeTag_map.value)
            }
            return nil
        case "struct":
            if let structTag_map = value as? Dictionary<String, AnyObject>,
               let address = structTag_map["address"] as? String,
               let module = structTag_map["module"] as? String,
               let name = structTag_map["name"] as? String,
               let typeParams = structTag_map["typeParams"] as? [Dictionary<String, AnyObject>]{
                guard let typeTags = try? SuiTypeTag.getTypeTags(type_list: typeParams), let _address = try? SuiAddress(value: address) else{return nil }
                return .Struct(SuiStructTag(address: _address, module: module, name: name, typeParams: typeTags))
            }
            return nil
        default:
            return nil
        }
    }
    // getTypeTag
    static func getTypeTags(type_list: [Dictionary<String, AnyObject>]) throws -> [SuiTypeTag]{
        var typeTags = [SuiTypeTag]()
        try type_list.forEach({ type_map in
            typeTags.append(try SuiTypeTag.getTypeTag(type_map: type_map))
        })
        return typeTags
    }
    static func getTypeTag(type_map: Dictionary<String, AnyObject>) throws -> SuiTypeTag{
        if let typeTag = type_map.first,
           let type_tag = SuiTypeTag.typeTagWithTypeKey(key: typeTag.key, value: typeTag.value){
            return type_tag
        }
        throw SuiError.DappError.OtherEror("Parse MoveCallTransaction TypeTag Error")
    }
}
extension SuiMoveCallTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let packageObjectId = dic["packageObjectId"] as? String,
              let module = dic["module"] as? String,
              let function = dic["function"] as? String,
              let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse MoveCallTransaction Package Error")
        }
        var typeArguments: TypeArguments?
        if let _typeArguments = dic["typeArguments"] as? [String]{
            typeArguments = .Strings(_typeArguments)
        }
        if let _typeArguments = dic["typeArguments"] as? [Dictionary<String, AnyObject>]{
            typeArguments = .TypeTags(try SuiTypeTag.getTypeTags(type_list: _typeArguments))
        }
        if typeArguments == nil{
            throw SuiError.DappError.OtherEror("Parse MoveCallTransaction TypeArguments Error")
        }
        var arguments = [MoveCallArgument]()
        if let _arguments = dic["arguments"] as? [AnyObject] {
           try _arguments.forEach { argument in
               if let pure = argument["Pure"] as? Dictionary<String, UInt8> {
                   arguments.append(MoveCallArgument.PureArg(SuiMoveCallTransaction.getPureArg(pureMap: pure)))
               } else{
                   arguments.append(MoveCallArgument.JsonValue(try SuiMoveCallTransaction.getJsonValue(argument: argument)))
               }
           }
        }
        let gasPayment = dic["gasPayment"] as? String
        let gasPrice = dic["gasPrice"] as? UInt64
        self.init(packageObjectId: packageObjectId, module: module, function: function, typeArguments: typeArguments!, arguments: arguments, gasPayment: gasPayment, gasBudget: gasBudget, gasPrice: gasPrice)
    }
   
    // jsonValue
    static func getJsonValue(argument: AnyObject) throws -> SuiJsonValue{
        if let str = argument as? String {
            return .Str(str)
        } else if let bool = argument as? Bool {
            return .Boolean(bool)
        } else if let number = argument as? UInt64 {
            return .Number(number)
        } else if let callArgMap = argument as? Dictionary<String, AnyObject> {
            return .CallArg(try SuiMoveCallTransaction.callArg(arg: callArgMap))
        } else if let array = argument as? Array<AnyObject>{
            var values = [SuiJsonValue]()
            try array.forEach { object in
                values.append(try getJsonValue(argument: object))
            }
            return .Array(values)
        }
        throw SuiError.DappError.OtherEror("Parse MoveCallTransaction jsonValue Error")
    }
    // callArg
    static func callArg(arg: Dictionary<String, AnyObject>) throws -> SuiCallArg{
        if let pure = arg["Pure"] as? Dictionary<String, UInt8> {
            return .Pure(getPureArg(pureMap: pure))
        } else if let objectMap = arg["Object"] as? Dictionary<String, AnyObject>{
            return .Object(try object(objectMap: objectMap))
        } else if let objectMap = arg["ObjVec"] as? Array<Dictionary<String, AnyObject>>{
            var objVec = [SuiObjectArg]()
            try objectMap.forEach { dic in
                objVec.append(try object(objectMap: dic))
            }
            return .ObjVec(objVec)
        }
        throw SuiError.DappError.OtherEror("Parse MoveCallTransaction callArg Error")
    }
    // pure
    static func getPureArg(pureMap: Dictionary<String, UInt8>) -> [UInt8]{
        var pures = [UInt8]()
        pureMap.sorted(by: {$0.0 < $1.0}).forEach { (_, value) in
            pures.append(value)
        }
        return pures
    }
    
    // object
    static func object(objectMap: Dictionary<String, AnyObject>) throws -> SuiObjectArg{
        if let immOrOwned = objectMap["ImmOrOwned"] as? Dictionary<String, AnyObject>{
            let objectRef = try objectRef(immOrOwned: immOrOwned)
            return .ImmOrOwned(objectRef)
        }
        if let shared = objectMap["Shared"] as? Dictionary<String, AnyObject>{
            let sharedObjectRef = try sharedObjectRef(shared: shared)
            return .Shared(sharedObjectRef)
        }
        throw SuiError.DappError.OtherEror("Parse MoveCallTransaction object Error")
    }
    
    // objectRef
    static func objectRef(immOrOwned: Dictionary<String, AnyObject>) throws -> SuiObjectRef{
        if let digest = immOrOwned["digest"] as? String,
           let objectId = immOrOwned["objectId"] as? String,
           let version = immOrOwned["version"] as? UInt64 {
            return SuiObjectRef(digest: digest, objectId: objectId, version: version)
        }
        throw SuiError.DappError.OtherEror("Parse MoveCallTransaction ImmOrOwned Error")
    }
    // Shared
     static func sharedObjectRef(shared: Dictionary<String, AnyObject>) throws -> SuiSharedObjectRef{
        if let objectId = shared["objectId"] as? String,
           let initialSharedVersion = shared["initialSharedVersion"] as? UInt64,
           let mutable = shared["mutable"] as? Bool {
            return SuiSharedObjectRef(objectId: objectId, initialSharedVersion: initialSharedVersion, mutable: mutable)
        }
        throw SuiError.DappError.OtherEror("Parse MoveCallTransaction shared Error")
    }
}
extension SuiPayAllSuiTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let inputCoins = dic["inputCoins"] as? [String],
              let recipient = dic["recipient"] as? String,
              let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse PayAllSuiTransaction Error")
        }
        let gasPrice = dic["gasPrice"] as? UInt64
        self.init(inputCoins: inputCoins, recipient: try SuiAddress(value: recipient), gasBudget: gasBudget, gasPrice: gasPrice)
    }
}
extension SuiPaySuiTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let inputCoins = dic["inputCoins"] as? [String],
              let recipients = dic["recipients"] as? [String],
              let amounts = dic["amounts"] as? [UInt64],
              let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse PaySuiTransaction Error")
        }
        let gasPrice = dic["gasPrice"] as? UInt64
        self.init(inputCoins: inputCoins, recipients: try recipients.map{try SuiAddress(value: $0)}, amounts: amounts, gasBudget: gasBudget, gasPrice: gasPrice)
    }
}
extension SuiPayTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let inputCoins = dic["inputCoins"] as? [String],
              let recipients = dic["recipients"] as? [String],
              let amounts = dic["amounts"] as? [UInt64],
              let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse PayTransaction Error")
        }
        let gasPayment = dic["gasPayment"] as? String
        let gasPrice = dic["gasPrice"] as? UInt64
        self.init(inputCoins: inputCoins, recipients: try recipients.map{try SuiAddress(value: $0)}, amounts: amounts, gasPayment: gasPayment, gasBudget: gasBudget, gasPrice: gasPrice)
    }
}
extension SuiPublishTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse PublishTransaction Error")
        }
        let gasPayment = dic["gasPayment"] as? String
        let gasPrice = dic["gasPrice"] as? UInt64
        if let compiledModules = dic["compiledModules"] as? [String] {
            self.init(compiledModules: .Array(compiledModules), gasPayment: gasPayment, gasBudget: gasBudget, gasPrice: gasPrice)
            return
        }
        if let compiledModules = dic["compiledModules"] as? [Dictionary<String, UInt8>] {
            var modulesList = [[UInt8]]()
            compiledModules.forEach { pureMap in
                var pures = [UInt8]()
                pureMap.sorted(by: {$0.0 < $1.0}).forEach { (_, value) in
                    pures.append(value)
                }
                modulesList.append(pures)
            }
            self.init(compiledModules: .Arrayx(modulesList), gasPayment: gasPayment, gasBudget: gasBudget, gasPrice: gasPrice)
            return
        }
        throw SuiError.DappError.OtherEror("Parse PublishTransaction Error")
    }
}
extension SuiSplitCoinTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let coinObjectId = dic["coinObjectId"] as? String,
              let splitAmounts = dic["splitAmounts"] as? [UInt64],
              let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse SplitCoinTransaction Error")
        }
        let gasPayment = dic["gasPayment"] as? String
        let gasPrice = dic["gasPrice"] as? UInt64
        self.init(coinObjectId: coinObjectId, splitAmounts: splitAmounts, gasPayment: gasPayment, gasBudget: gasBudget, gasPrice: gasPrice)
    }
}
extension SuiTransferObjectTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let objectId = dic["objectId"] as? String,
              let recipient = dic["recipient"] as? String,
              let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse TransferObjectTransaction Error")
        }
        let gasPayment = dic["gasPayment"] as? String
        let gasPrice = dic["gasPrice"] as? UInt64
        self.init(objectId: objectId, gasPayment: gasPayment, recipient: try SuiAddress(value: recipient), gasBudget: gasBudget, gasPrice: gasPrice)
    }
}
extension SuiTransferSuiTransaction: SuiDappUnserializedSignableTransaction{
    public init(dic: Dictionary<String, AnyObject>) throws {
        guard let suiObjectId = dic["suiObjectId"] as? String,
              let recipient = dic["recipient"] as? String,
              let gasBudget = dic["gasBudget"] as? UInt64 else {
            throw SuiError.DappError.OtherEror("Parse TransferSuiTransaction Error")
        }
        let gasPrice = dic["gasPrice"] as? UInt64
        let amount = dic["amount"] as? UInt64
        self.init(suiObjectId: suiObjectId, recipient: try SuiAddress(value: recipient), amount: amount, gasBudget: gasBudget, gasPrice: gasPrice)
    }
}
