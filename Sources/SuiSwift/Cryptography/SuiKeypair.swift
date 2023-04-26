//
//  SuiKeypair.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation

public protocol SuiKeypair{
    var secretKey: Data{get}
    var publicData: Data { get }
    
    static func randomKeyPair() throws -> SuiKeypair
    init(seed: Data, path: String) throws
    init(mnemonics: String, derivationPath: SuiDerivationPath) throws
    init(mnemonics: String, path: String) throws
    init(secretKey: Data) throws
    init(key: Data) throws
    func getPublicKey() throws -> any SuiPublicKey
    func signData(message: Data) throws -> Data
    func getKeyScheme() -> SuiSignatureScheme
}

public enum SuiDerivationPath{
    /**
     * Parse and validate a path that is compliant to SLIP-0010 in form m/44'/784'/{account_index}'/{change_index}'/{address_index}'.
     *
     * @param path path string (e.g. `m/44'/784'/0'/0'/0'`).
     */
    case DERVIATION_PATH_PURPOSE_ED25519(address_index: String)
    /**
     * Parse and validate a path that is compliant to BIP-32 in form m/54'/784'/{account_index}'/{change_index}/{address_index}.
     * Note that the purpose for Secp256k1 is registered as 54, to differentiate from Ed25519 with purpose 44.
     *
     * @param path path string (e.g. `m/54'/784'/0'/0/0`).
     */
    case DERVIATION_PATH_PURPOSE_SECP256K1(address_index: String)
    
    public func PATH() -> String{
        switch self {
        case .DERVIATION_PATH_PURPOSE_ED25519(let address_index):
            return "m/44'/784'/0'/0'/\(address_index)'"
        case .DERVIATION_PATH_PURPOSE_SECP256K1(let address_index):
            return "m/54'/784'/0'/0/\(address_index)"
        }
    }
}
