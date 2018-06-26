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
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
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
        arguments: [String: Any] = [:], content: Data? = nil,
        resultHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask? {
        return invoke(method, path: path, arguments: arguments, content: content, responseHandler: { content, contentType in
            let result: T?
            if (contentType.hasPrefix(WebServiceProxy.applicationJSON)) {
                result = try JSONSerialization.jsonObject(with: content, options: []) as? T
            } else {
                result = nil
            }

            return result
        }, resultHandler: resultHandler)
    }

    @discardableResult
    public func invoke<T: Decodable>(_ method: Method, path: String,
        arguments: [String: Any] = [:], content: Data? = nil,
        resultHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask? {
        return invoke(method, path: path, arguments: arguments, content: content, responseHandler: { content, contentType in
            let result: T?
            if (contentType.hasPrefix(WebServiceProxy.applicationJSON)) {
                result = try JSONDecoder().decode(T.self, from: content)
            } else {
                result = nil
            }

            return result
        }, resultHandler: resultHandler)
    }

    @discardableResult
    public func invoke<T>(_ method: Method, path: String,
        arguments: [String: Any] = [:], content: Data? = nil,
        responseHandler: @escaping (Data, String) throws -> T?,
        resultHandler: @escaping (T?, Error?) -> Void) -> URLSessionTask? {
        let query = (method != .post || content != nil) ? encodeQuery(for: arguments) : ""

        let task: URLSessionDataTask?
        if let url = URL(string: path + (query.isEmpty ? "" : "?" + query), relativeTo: serverURL) {
            var urlRequest = URLRequest(url: url)

            urlRequest.httpMethod = method.rawValue

            let httpBody: Data?
            if (method == .post && content == nil) {
                let contentType: String
                switch encoding {
                case .applicationXWWWFormURLEncoded:
                    contentType = "application/x-www-form-urlencoded"
                    httpBody = encodeApplicationXWWWFormURLEncodedData(for: arguments)

                case .multipartFormData:
                    contentType = "multipart/form-data; boundary=\(multipartBoundary)"
                    httpBody = encodeMultipartFormData(for: arguments)
                }

                urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
            } else {
                httpBody = content
            }

            urlRequest.httpBody = httpBody

            task = session.dataTask(with: urlRequest) { data, urlResponse, error in
                if let content = data, let contentType = urlResponse?.mimeType, error == nil {
                    do {
                        let result = try responseHandler(content, contentType)

                        OperationQueue.main.addOperation {
                            resultHandler(result, nil)
                        }
                    } catch {
                        OperationQueue.main.addOperation {
                            resultHandler(nil, error)
                        }
                    }
                } else {
                    OperationQueue.main.addOperation {
                        resultHandler(nil, error)
                    }
                }
            }
        } else {
            task = nil
        }

        task?.resume()

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

    func encodeApplicationXWWWFormURLEncodedData(for arguments: [String: Any]) -> Data {
        var body = Data()

        body.append(utf8DataFor: encodeQuery(for: arguments))

        return body
    }

    func encodeMultipartFormData(for arguments: [String: Any]) -> Data {
        var body = Data()

        for argument in arguments {
            guard let key = argument.key.urlEncodedString, !key.isEmpty else {
                continue
            }

            for element in argument.value as? [Any] ?? [argument.value] {
                body.append(utf8DataFor: "--%\(multipartBoundary)\r\n")
                body.append(utf8DataFor: "Content-Disposition: form-data; name=\"\(key)\"")

                if let url = element as? URL {
                    body.append(utf8DataFor: "; filename=\"\(url.lastPathComponent)\"\r\n")
                    body.append(utf8DataFor: "Content-Type: application/octet-stream\r\n\r\n")

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

        body.append(utf8DataFor: "--\(multipartBoundary)--\r\n")

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
