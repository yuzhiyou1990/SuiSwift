//
//  File.swift
//  
//
//  Created by li shuai on 2022/11/4.
//

import Foundation

extension SuiRpcApiVersion{
    public static func parseVersionFromString(version: String) -> SuiRpcApiVersion? {
        let numbers = version.split(separator: ".")
        guard let major = Int(numbers[0]),
              let minor = Int(numbers[1]),
              let patch = Int(numbers[2]) else{
            return nil
        }
        return SuiRpcApiVersion(major: major, minor: minor, patch: patch)
    }
}

extension Base64String: Decodable{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = Base64String(value: str)
            return
        }
        throw SuiError.RPCError.DecodingError("Base64String Decoder Error")
    }
}
extension SuiData{
    enum CodingKeys: String, CodingKey {
        case dataType = "dataType"
    }
    public func balance() -> String{
        switch dataObject{
        case .MoveObject(let moveObject): return moveObject.getBalance()
        case .MovePackage(_),.ParseError(_):  return "0"
        }
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(String.self, forKey: .dataType){
            dataType = value
        }
        
        let singleContainer = try decoder.singleValueContainer()
        if let package = try? singleContainer.decode(SuiMovePackage.self) {
            dataObject = .MovePackage(package)
            return
        }
        if let moveObject = try? singleContainer.decode(SuiMoveObject.self) {
            dataObject = .MoveObject(moveObject)
            return
        }
        dataObject = .ParseError("SuiData Parse Error")
    }
}
extension SuiObject{
    public func type() -> String?{
        switch data.dataObject{
        case .MoveObject(let moveObject): return moveObject.getType()
        case .MovePackage(_), .ParseError(_): return nil
        }
    }
    public func id() -> String? {
        switch data.dataObject{
        case .MovePackage(_), .ParseError(_): return nil
        case .MoveObject(let moveObject): return moveObject.getObjectId()
        }
    }
    public func balance() -> String {
        switch data.dataObject{
        case .MovePackage(_), .ParseError(_): return "0"
        case .MoveObject(let moveObject): return moveObject.getBalance()
        }
    }
}

extension SuiObjectOwner{
    
    enum CodingKeys: String, CodingKey {
        case AddressOwner = "AddressOwner"
        case ObjectOwner = "ObjectOwner"
        case SingleOwner = "SingleOwner"
        case Immutable = "Immutable"
        case Shared = "Shared"
        case Unknow
    }
    public init(from decoder: Decoder) throws {
        if  let container = try? decoder.container(keyedBy: CodingKeys.self){
            if let value = try? container.decode(SuiAddress.self, forKey: .AddressOwner){
                self = .AddressOwner(value)
                return
            }
            if let value = try? container.decode(SuiAddress.self, forKey: .ObjectOwner){
                self = .ObjectOwner(value)
                return
            }
            if let value = try? container.decode(SuiAddress.self, forKey: .SingleOwner){
                self = .SingleOwner(value)
                return
            }
            if let value = try? container.decode(SuiObjectOwner.SuiShared.self, forKey: .Shared){
                self = .Shared(value)
                return
            }
        }
        if let singleContainer = try? decoder.singleValueContainer(){
            if let name = try? singleContainer.decode(String.self) {
                self = .Immutable(name)
                return
            }
        }
        self = .Unknow(SuiError.RPCError.DecodingError("SuiObjectOwner Parse Error"))
    }
}


extension SuiGetObjectDataResponse{
    public enum CodingKeys: CodingKey {
        case status
        case details
    }
    
    public enum Status: String{
        case Exists
        case Deleted
        case NotExists
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(SuiObjectStatus.self, forKey: .status)
        if let suiObject = try? container.decode(SuiObject.self, forKey: .details) {
            self.details = SuiGetObjectDetails.SuiObject(suiObject)
            return
        }
        if let objectId = try? container.decode(SuiObjectId.self, forKey: .details) {
            self.details = SuiGetObjectDetails.ObjectId(objectId)
            return
        }
        if let suiObjectRef = try? container.decode(SuiObjectRef.self, forKey: .details) {
            self.details = SuiGetObjectDetails.SuiObjectRef(suiObjectRef)
            return
        }
        throw SuiError.RPCError.DecodingError("Decode SuiGetObjectDataResponse Error")
    }
    
    // https://github.com/MystenLabs/sui/blob/45293b6ffaf96d778719caba4f1f3319786991e8/sdk/typescript/src/types/objects.ts
    public func getObjectReference() -> SuiObjectRef?{
        switch status {
        case .Exists:
            guard case let .SuiObject( suiObject) = details else{
                return nil
            }
            return suiObject.reference
        case .Deleted:
            guard case let .SuiObjectRef(suiObjectRef) = details else {
                return nil
            }
            return suiObjectRef
        case .NotExists:
            return nil
        }
    }
    public func getSharedObjectInitialVersion() -> Int?{
        switch status {
        case .Exists:
            guard case let .SuiObject( suiObject) = details else{
                return nil
            }
            switch suiObject.owner{
            case .Shared(let shared):
                return shared.initial_shared_version
            default:
                return nil
            }
        case .Deleted: return nil
        case .NotExists: return nil
        }
    }
}



//move call

extension SuiMoveFunctionArgType{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .Str(str)
            return
        }
        if let argTypeObject = try? container.decode(ArgTypeObject.self) {
            self = .Object(argTypeObject)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiMoveFunctionArgType Decoder Error")
    }
}

extension SuiMoveNormalizedType{
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .Str(str)
            return
        }
        if let parameterType = try? container.decode(SuiMoveNormalizedTypeParameterType.self) {
            self = .MoveNormalizedTypeParameterType(parameterType)
            return
        }
        if let moveNormalizedTypeReference_Reference = try? container.decode(SuiMoveNormalizedTypeReference.self) {
            self = .Reference(moveNormalizedTypeReference_Reference)
            return
        }
        if let moveNormalizedTypeReference_MutableReference = try? container.decode(SuiMoveNormalizedTypeMutableReference.self) {
            self = .MutableReference(moveNormalizedTypeReference_MutableReference)
            return
        }
        if let vector = try? container.decode(SuiMoveNormalizedTypeVector.self) {
            self = .Vector(vector)
            return
        }
        if let structType = try? container.decode(SuiMoveNormalizedStructType.self) {
            self = .MoveNormalizedStructType(structType)
            return
        }
        throw SuiError.RPCError.DecodingError("SuiMoveNormalizedType Decoder Error")
    }
    
    public func extractStructTag() -> SuiMoveNormalizedStructType?{
        switch self {
        case .Str(_): return nil
        case .MoveNormalizedTypeParameterType(_):  return nil
        case .Reference(let suiMoveNormalizedTypeReference):
            return suiMoveNormalizedTypeReference.reference.extractStructTag()
        case .MutableReference(let suiMoveNormalizedTypeMutableReference):
            return suiMoveNormalizedTypeMutableReference.mutableReference.extractStructTag()
        case .Vector(_):  return nil
        case .MoveNormalizedStructType(let suiMoveNormalizedStructType):
            return suiMoveNormalizedStructType
        }
    }
}
