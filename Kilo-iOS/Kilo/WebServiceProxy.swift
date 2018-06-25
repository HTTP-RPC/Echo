//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

public class WebServiceProxy {
    public enum Encoding: Int {
        case applicationXWWWFormURLEncoded
        case multipartFormData
    }

    public enum Method: String {
        case get
        case post
        case put
        case patch
        case delete
    }

    public private(set) var session: URLSession
    public private(set) var serverURL: URL

    public var encoding: Encoding

    static let applicationJSON = "application/json"

    public init(session: URLSession, serverURL: URL) {
        self.session = session
        self.serverURL = serverURL

        encoding = .applicationXWWWFormURLEncoded
    }

    @discardableResult
    public func invoke<T>(_ method: Method, path: String,
        arguments: [String: Any] = [:], body: Data? = nil,
        responseHandler: @escaping (Data, String) throws -> T?,
        resultHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask? {
        // TODO
        return nil
    }

    @discardableResult
    public func invoke<T: Decodable>(_ method: Method, path: String,
        arguments: [String: Any] = [:], body: Data? = nil,
        resultHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask? {
        return invoke(method, path: path, arguments: arguments, body: body, responseHandler: { data, contentType in
            let result: T?
            if (contentType.hasPrefix(WebServiceProxy.applicationJSON)) {
                let jsonDecoder = JSONDecoder()

                result = try jsonDecoder.decode(T.self, from: data)
            } else {
                result = nil
            }

            return result
        }, resultHandler: resultHandler)
    }

    @discardableResult
    public func invoke<T>(_ method: Method, path: String,
        arguments: [String: Any] = [:], body: Data? = nil,
        resultHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask? {
        return invoke(method, path: path, arguments: arguments, body: body, responseHandler: { data, contentType in
            let result: T?
            if (contentType.hasPrefix(WebServiceProxy.applicationJSON)) {
                result = try JSONSerialization.jsonObject(with: data, options: []) as? T
            } else {
                result = nil
            }

            return result
        }, resultHandler: resultHandler)
    }
}
