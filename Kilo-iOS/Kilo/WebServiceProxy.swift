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
import MobileCoreServices

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

    let multipartBoundary = UUID().uuidString

    static let applicationJSON = "application/json"

    public init(session: URLSession, serverURL: URL) {
        self.session = session
        self.serverURL = serverURL

        encoding = .applicationXWWWFormURLEncoded
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

    @discardableResult
    public func invoke<T: Decodable>(_ method: Method, path: String,
        arguments: [String: Any] = [:], body: Data? = nil,
        resultHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask? {
        return invoke(method, path: path, arguments: arguments, body: body, responseHandler: { data, contentType in
            let result: T?
            if (contentType.hasPrefix(WebServiceProxy.applicationJSON)) {
                result = try JSONDecoder().decode(T.self, from: data)
            } else {
                result = nil
            }

            return result
        }, resultHandler: resultHandler)
    }

    @discardableResult
    public func invoke<T>(_ method: Method, path: String,
        arguments: [String: Any] = [:], body: Data? = nil,
        responseHandler: @escaping (Data, String) throws -> T?,
        resultHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask? {
        let task: URLSessionDataTask? = nil

        // TODO

        return task
    }

    func encodeQuery(for arguments: [String: Any]) -> String {
        var query = ""

        for argument in arguments {
            guard let key = argument.key.urlEncodedString, !key.isEmpty else {
                continue
            }

            for element in argument.value as? [Any] ?? [argument.value] {
                if (query.count > 0) {
                    query += "&"
                }

                query += key + "="

                if let value = WebServiceProxy.value(for: element)?.description.urlEncodedString {
                    query += value
                }
            }
        }

        return query
    }

    func encodeMultipartFormData(for arguments: [String: Any]) -> Data {
        var body = Data()

        for argument in arguments {
            guard let key = argument.key.urlEncodedString, !key.isEmpty else {
                continue
            }

            for element in argument.value as? [Any] ?? [argument.value] {
                body.append(utf8DataFor: String(format: "--%@\r\n", multipartBoundary))
                body.append(utf8DataFor: String(format: "Content-Disposition: form-data; name=\"%@\"", key))

                if let url = element as? URL {
                    body.append(utf8DataFor: String(format: "; filename=\"%@\"\r\n", url.lastPathComponent))
                    body.append(utf8DataFor: String(format: "Content-Type: application/octet-stream%@\r\n\r\n"))

                    if let data = try? Data(contentsOf: url) {
                        body.append(data)
                    }
                } else {
                    body.append(utf8DataFor: "\r\n\r\n")

                    if let value = WebServiceProxy.value(for: element)?.description {
                        body.append(utf8DataFor: value)
                    }
                }

                body.append(utf8DataFor: "\r\n")
            }
        }

        body.append(utf8DataFor: String(format:"--%@--\r\n", multipartBoundary))

        return body
    }

    static func value(for element: Any) -> CustomStringConvertible? {
        let value: CustomStringConvertible?
        if let date = element as? Date {
            value = date.timeIntervalSince1970 * 1000
        } else if let customStringConvertible = element as? CustomStringConvertible {
            value = customStringConvertible
        } else {
            value = nil
        }

        return value
    }
}

extension String {
    var urlEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "+", with: "%2B")
    }
}

extension Data {
    mutating func append(utf8DataFor string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
