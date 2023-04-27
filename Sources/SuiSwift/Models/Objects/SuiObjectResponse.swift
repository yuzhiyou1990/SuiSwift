//
//  File.swift
//  
//
//  Created by li shuai on 2023/4/27.
//

import Foundation

public struct SuiObjectResponse: Decodable{
    public let data: SuiObjectData?
    public let error: SuiObjectResponseError?
}

extension SuiObjectResponse{
    public func getSharedObjectInitialVersion() -> Int?{
        if let objectData = self.data, let owner = objectData.owner {
            if case .Shared(let shared) = owner{
                return shared.initial_shared_version
            }
        }
        return nil
    }
    public func getObjectReference() -> SuiObjectRef?{
        return self.data?.getObjectReference()
    }
}

extension SuiObjectResponse: SuiObjectDataI{
    public func getType() -> String? {
        return  self.data?.getType()
    }
}
