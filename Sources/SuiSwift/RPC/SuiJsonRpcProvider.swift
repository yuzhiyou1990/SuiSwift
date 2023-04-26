//
//  SuiJsonRpcProvider.swift
//  
//
//  Created by li shuai on 2022/12/20.
//

import Foundation
import PromiseKit
public class SuiJsonRpcProvider{
    public var url: URL
    public static var shared = SuiJsonRpcProvider()
    private var session: URLSession
    lazy var queue: DispatchQueue = {
        return DispatchQueue(label: "SUI.POST")
    }()
    public struct RequestParam<T: Encodable>: Encodable{
        public var method: RPCMethod
        public var jsonrpc: String
        public var params: T
        public var id: String
        public init(method: RPCMethod, params: T) {
            self.method = method
            self.jsonrpc = "2.0"
            self.params = params
            self.id = UUID().uuidString
        }
    }
    public struct ResponseParam<Result: Decodable>: Decodable{
        public var jsonrpc: String
        public var result: Result
        public var id: String
    }
    public init(url: URL = URL(string: "https://wallet-rpc.testnet.sui.io")!) {
        self.url = url
        self.session = URLSession(configuration: .default)
    }
    
    public func sendRequest<T: Encodable, Result: Decodable>(method: RPCMethod, params: T) -> Promise<Result>{
        
        return Promise { seal in
            guard let body = try? JSONEncoder().encode(RequestParam(method: method, params: params)) else{
                seal.reject(SuiError.RPCError.EncodingError)
                return
            }
            self.request(body: body).done { data in
                let decoder = JSONDecoder()
                do {
                    seal.fulfill(try decoder.decode(ResponseParam<Result>.self, from: data).result)
                } catch {
                    seal.reject(SuiError.RPCError.DecodingError(error.localizedDescription, String(data: data, encoding: .utf8)))
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func sendBatchRequest<T: Encodable, Result: Decodable>(params: [(method: RPCMethod, param: T)]) -> Promise<[Result]>{
        return Promise { seal in
            let params = params.map{RequestParam(method: $0.method, params: $0.param)}
            guard let body = try? JSONEncoder().encode(params) else{
                seal.reject(SuiError.RPCError.EncodingError)
                return
            }
            self.request(body: body).done { data in
                let decoder = JSONDecoder()
                do {
                    let responseParams = try decoder.decode([ResponseParam<Result>].self, from: data)
                    let results = responseParams.map{$0.result}
                    seal.fulfill(results)
                } catch {
                    seal.reject(SuiError.RPCError.DecodingError(error.localizedDescription, String(data: data, encoding: .utf8)))
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    private func request(body: Data) -> Promise<Data>{
        let rp = Promise<Data>.pending()
        var task: URLSessionTask?
        self.queue.async {
            var urlRequest = URLRequest(url: self.url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = body
            task = self.session.dataTask(with: urlRequest){ (data, _, error) in
                guard error == nil else {
                    rp.resolver.reject(error!)
                    return
                }
                guard data != nil else {
                    rp.resolver.reject(SuiError.RPCError.DecodingError("Node response is empty"))
                    return
                }
                rp.resolver.fulfill(data!)
            }
            task?.resume()
        }
        return rp.promise.ensure(on: queue) {
            task = nil
        }.map(on: queue){ (data: Data) throws -> Data in
            return data
        }
    }
}
