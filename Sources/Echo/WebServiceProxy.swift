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

/**
 Web service proxy class.
 */
public class WebServiceProxy {
    /**
     Service method options.
     */
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    /**
     Encoding options for POST requests.
     */
    public enum Encoding: Int {
        case applicationXWWWFormURLEncoded
        case multipartFormData
    }

    /**
     Response handler type alias.
     - parameter content: The response content.
     - parameter contentType: The response content type, or `nil` if the content type is not known.
     */
    public typealias ResponseHandler<T> = (_ content: Data, _ contentType: String?) throws -> T

    /**
     Creates a new web service proxy.
     - parameter session: The URL session the service proxy will use to issue HTTP requests.
     - parameter baseURL: The base URL of the service.
     */
    public init(session: URLSession, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    /**
     The URL session the service proxy will use to issue HTTP requests.
     */
    public private(set) var session: URLSession

    /**
     The base URL of the service.
     */
    public private(set) var baseURL: URL

    /**
     The encoding used to submit POST requests.
     */
    public var encoding: Encoding = .applicationXWWWFormURLEncoded

    /**
     * Common request headers.
     */
    public var headers: [String: String] = [:]

    /**
     * Constant representing an unspecified value.
     */
    public static let undefined: Any = NSNull()
    
    // JSON encoder
    private static let jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()

        jsonEncoder.outputFormatting = .prettyPrinted
        jsonEncoder.dateEncodingStrategy = .millisecondsSince1970
        
        return jsonEncoder
    }()
    
    // JSON decoder
    private static let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        
        jsonDecoder.dateDecodingStrategy = .millisecondsSince1970
        
        return jsonDecoder
    }()

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter headers: Request-specific headers.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for no content.
     - parameter contentType: The request content type, or `nil` for no content type.
     */
    public func invoke(_ method: Method, path: String,
        headers: [String: String] = [:], arguments: [String: Any] = [:],
        content: Data? = nil, contentType: String? = nil) async throws {
        try await invoke(method, path: path, headers: headers, arguments: arguments, content: content, contentType: contentType, responseHandler: { _, _ in })
    }

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter headers: Request-specific headers.
     - parameter arguments: The request arguments.
     - parameter body: The request body.
     */
    public func invoke<B: Encodable>(_ method: Method, path: String,
        headers: [String: String] = [:], arguments: [String: Any] = [:],
        body: B) async throws {
        try await invoke(method, path: path, headers: headers, arguments: arguments, content: try WebServiceProxy.jsonEncoder.encode(body), contentType: "application/json")
    }

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter headers: Request-specific headers.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for no content.
     - parameter contentType: The request content type, or `nil` for no content type.
     - returns The response body.
     */
    public func invoke<T: Decodable>(_ method: Method, path: String,
        headers: [String: String] = [:], arguments: [String: Any] = [:],
        content: Data? = nil, contentType: String? = nil) async throws -> T {
        return try await invoke(method, path: path, headers: headers, arguments: arguments, content: content, contentType: contentType, responseHandler: { content, _ in
            return try WebServiceProxy.jsonDecoder.decode(T.self, from: content)
        })
    }

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter headers: Request-specific headers.
     - parameter arguments: The request arguments.
     - parameter body: The request body.
     - returns The response body.
     */
    public func invoke<B: Encodable, T: Decodable>(_ method: Method, path: String,
        headers: [String: String] = [:], arguments: [String: Any] = [:],
        body: B) async throws -> T {
        return try await invoke(method, path: path, headers: headers, arguments: arguments, content: try WebServiceProxy.jsonEncoder.encode(body), contentType: "application/json")
    }

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter headers: Request-specific headers.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for no content.
     - parameter contentType: The request content type, or `nil` for no content type.
     - parameter responseHandler: A callback that will be invoked to handle the response.
     - returns The response body.
     */
    public func invoke<T>(_ method: Method, path: String,
        headers: [String: String] = [:], arguments: [String: Any] = [:],
        content: Data? = nil, contentType: String? = nil,
        responseHandler: @escaping ResponseHandler<T>) async throws -> T {
        let url: URL?
        if (method == .post && content == nil) {
            url = URL(string: path, relativeTo: baseURL)
        } else {
            let query = encodeQuery(for: arguments)
            
            if (query.isEmpty) {
                url = URL(string: path, relativeTo: baseURL)
            } else {
                url = URL(string: path + "?" + query, relativeTo: baseURL)
            }
        }
        
        if (url == nil) {
            throw WebServiceError(errorDescription: "Invalid path.", statusCode: 0)
        }
        
        var urlRequest = URLRequest(url: url!)

        urlRequest.httpMethod = method.rawValue

        for (key, value) in self.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if (method == .post && content == nil) {
            switch encoding {
            case .applicationXWWWFormURLEncoded:
                urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = encodeApplicationXWWWFormURLEncodedData(for: arguments)

            case .multipartFormData:
                let multipartBoundary = UUID().uuidString

                urlRequest.setValue("multipart/form-data; boundary=\(multipartBoundary)", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = encodeMultipartFormData(for: arguments, multipartBoundary: multipartBoundary)
            }
        } else {
            if (content != nil) {
                urlRequest.setValue(contentType ?? "application/octet-stream", forHTTPHeaderField: "Content-Type")
            }

            urlRequest.httpBody = content
        }

        let (content, urlResponse) = try await session.data(for: urlRequest)
        
        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            throw WebServiceError(errorDescription: "Unexpected response.", statusCode: 0)
        }
        
        let statusCode = httpURLResponse.statusCode
        let contentType = httpURLResponse.mimeType

        if (statusCode / 100 == 2) {
            return try responseHandler(content, contentType)
        } else {
            let errorDescription: String?
            if (contentType?.hasPrefix("text/") ?? false) {
                errorDescription = String(data: content, encoding: .utf8)
            } else {
                errorDescription = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            }

            throw WebServiceError(errorDescription: errorDescription, statusCode: statusCode)
        }
    }

    func encodeQuery(for arguments: [String: Any]) -> String {
        var urlQueryItems: [URLQueryItem] = []

        for argument in arguments {
            if (argument.key.isEmpty) {
                continue
            }

            for element in argument.value as? [Any] ?? [argument.value] {
                guard let value = value(for: element) else {
                    continue
                }

                urlQueryItems.append(URLQueryItem(name: argument.key, value: value))
            }
        }

        var urlComponents = URLComponents()

        urlComponents.queryItems = urlQueryItems

        return urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") ?? ""
    }

    func encodeApplicationXWWWFormURLEncodedData(for arguments: [String: Any]) -> Data {
        var body = Data()

        body.append(utf8DataFor: encodeQuery(for: arguments))

        return body
    }

    func encodeMultipartFormData(for arguments: [String: Any], multipartBoundary: String) -> Data {
        var body = Data()

        for argument in arguments {
            for element in argument.value as? [Any] ?? [argument.value] {
                body.append(utf8DataFor: "--\(multipartBoundary)\r\n")
                body.append(utf8DataFor: "Content-Disposition: form-data; name=\"\(argument.key)\"")

                if let url = element as? URL {
                    body.append(utf8DataFor: "; filename=\"\(url.lastPathComponent)\"\r\n")
                    body.append(utf8DataFor: "Content-Type: application/octet-stream\r\n\r\n")

                    if let data = try? Data(contentsOf: url) {
                        body.append(data)
                    }
                } else {
                    body.append(utf8DataFor: "\r\n\r\n")

                    if let value = value(for: element) {
                        body.append(utf8DataFor: value)
                    }
                }

                body.append(utf8DataFor: "\r\n")
            }
        }

        body.append(utf8DataFor: "--\(multipartBoundary)--\r\n")

        return body
    }

    func value(for element: Any) -> String? {
        if (element is NSNull) {
            return nil
        } else if let date = element as? Date {
            return String(describing: Int64(date.timeIntervalSince1970 * 1000))
        } else {
            return String(describing: element)
        }
    }
}

extension Data {
    mutating func append(utf8DataFor string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
