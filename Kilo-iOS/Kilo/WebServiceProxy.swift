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

/**
 Web service invocation proxy.
 */
public class WebServiceProxy {
    /**
     Encoding options for POST requests.
     */
    public enum Encoding: Int {
        case applicationXWWWFormURLEncoded
        case multipartFormData
    }

    /**
     Service method options.
     */
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    /**
     The URL session the service proxy will use to issue HTTP requests.
     */
    public private(set) var session: URLSession

    /**
     The server URL.
     */
    public private(set) var serverURL: URL

    /**
     The encoding used to submit POST requests.
     */
    public var encoding: Encoding

    /**
     Creates a new web service proxy.

     - parameter session: The URL session the service proxy will use to issue HTTP requests.
     - parameter serverURL: The server URL.
     */
    public init(session: URLSession, serverURL: URL) {
        self.session = session
        self.serverURL = serverURL

        encoding = .applicationXWWWFormURLEncoded
    }

    /**
     Invokes a web service method.

     - parameter method: The HTTP verb associated with the request.
     - parameter path: The path associated with the request.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for the default content.
     - parameter contentType: The request content type, or `nil` for the default content type.
     - parameter resultHandler: A callback that will be invoked upon completion of the request.

     - returns: A URL session task representing the invocation request, or `nil` if the task could not be created.
     */
    @discardableResult
    public func invoke<T>(_ method: Method, path: String,
        arguments: [String: Any] = [:], content: Data? = nil, contentType: String? = nil,
        resultHandler: @escaping (_ result: T?, _ error: Error?) -> Void) -> URLSessionTask? {
        return invoke(method, path: path, arguments: arguments, content: content, responseHandler: { content, contentType in
            return try JSONSerialization.jsonObject(with: content, options: []) as? T
        }, resultHandler: resultHandler)
    }

    /**
     Invokes a web service method.

     - parameter method: The HTTP verb associated with the request.
     - parameter path: The path associated with the request.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for the default content.
     - parameter contentType: The request content type, or `nil` for the default content type.
     - parameter resultHandler: A callback that will be invoked upon completion of the request.

     - returns: A URL session task representing the invocation request, or `nil` if the task could not be created.
     */
    @discardableResult
    public func invoke<T: Decodable>(_ method: Method, path: String,
        arguments: [String: Any] = [:], content: Data? = nil, contentType: String? = nil,
        resultHandler: @escaping (_ result: T?, _ error: Error?) -> Void) -> URLSessionTask? {
        return invoke(method, path: path, arguments: arguments, content: content, responseHandler: { content, contentType in
            let jsonDecoder = JSONDecoder()
            
            jsonDecoder.dateDecodingStrategy = .millisecondsSince1970

            return try jsonDecoder.decode(T.self, from: content)
        }, resultHandler: resultHandler)
    }

    /**
     Invokes a web service method.

     - parameter method: The HTTP verb associated with the request.
     - parameter path: The path associated with the request.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for the default content.
     - parameter contentType: The request content type, or `nil` for the default content type.
     - parameter responseHandler: A callback that will be invoked upon completion of the request.
     - parameter resultHandler: A callback that will be invoked upon completion of the request.

     - returns: A URL session task representing the invocation request, or `nil` if the task could not be created.
     */
    @discardableResult
    public func invoke<T>(_ method: Method, path: String,
        arguments: [String: Any] = [:], content: Data? = nil, contentType: String? = nil,
        responseHandler: @escaping (_ content: Data, _ contentType: String?) throws -> T?,
        resultHandler: @escaping (_ result: T?, _ error: Error?) -> Void) -> URLSessionTask? {
        let query = (method != .post || content != nil) ? encodeQuery(for: arguments) : ""

        let task: URLSessionDataTask?
        if let url = URL(string: path + (query.isEmpty ? "" : "?" + query), relativeTo: serverURL) {
            var urlRequest = URLRequest(url: url)

            urlRequest.httpMethod = method.rawValue

            switch method {
            case .post where content == nil:
                switch encoding {
                case .applicationXWWWFormURLEncoded:
                    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = encodeApplicationXWWWFormURLEncodedData(for: arguments)

                case .multipartFormData:
                    let multipartBoundary = UUID().uuidString

                    urlRequest.setValue("multipart/form-data; boundary=\(multipartBoundary)", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = encodeMultipartFormData(for: arguments, multipartBoundary: multipartBoundary)
                }

            default:
                if (content != nil) {
                    urlRequest.setValue(contentType ?? "application/octet-stream", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = content
                }
            }

            task = session.dataTask(with: urlRequest) { data, urlResponse, error in
                if let httpURLResponse = urlResponse as? HTTPURLResponse {
                    do {
                        let result: T?
                        if (httpURLResponse.statusCode / 100 == 2) {
                            if let content = data, !content.isEmpty {
                                result = try responseHandler(content, httpURLResponse.mimeType)
                            } else {
                                result = nil
                            }
                        } else {
                            guard let errorDomain = Bundle(for: WebServiceProxy.self).bundleIdentifier else {
                                fatalError()
                            }

                            var userInfo = [
                                NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: httpURLResponse.statusCode)
                            ]

                            if let content = data, let contentType = httpURLResponse.mimeType, contentType.hasPrefix("text/") {
                                userInfo[NSDebugDescriptionErrorKey] = String(data: content, encoding: .utf8)
                            }

                            throw NSError(domain: errorDomain, code: httpURLResponse.statusCode, userInfo: userInfo)
                        }

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

    func encodeMultipartFormData(for arguments: [String: Any], multipartBoundary: String) -> Data {
        var body = Data()

        for argument in arguments {
            guard let key = argument.key.urlEncodedString, !key.isEmpty else {
                continue
            }

            for element in argument.value as? [Any] ?? [argument.value] {
                body.append(utf8DataFor: "--\(multipartBoundary)\r\n")
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
            value = Int64(date.timeIntervalSince1970 * 1000)
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
