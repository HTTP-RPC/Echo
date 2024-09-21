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
     * Request headers.
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

    private static let applicationJSON = "application/json"

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for no content.
     - parameter contentType: The request content type, or `nil` for no content type.
     */
    public func invoke(_ method: Method, path: String,
        arguments: [String: Any] = [:],
        content: Data? = nil,
        contentType: String? = nil) async throws {
        try await invoke(method, path: path,
            arguments: arguments,
            content: content,
            contentType: contentType) { _, _ in }
    }

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter arguments: The request arguments.
     - parameter body: The request body.
     */
    public func invoke<B: Encodable>(_ method: Method, path: String,
        arguments: [String: Any] = [:],
        body: B) async throws {
        try await invoke(method, path: path,
            arguments: arguments,
            content: try WebServiceProxy.jsonEncoder.encode(body),
            contentType: WebServiceProxy.applicationJSON)
    }

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for no content.
     - parameter contentType: The request content type, or `nil` for no content type.
     - returns The response body.
     */
    public func invoke<T: Decodable>(_ method: Method, path: String,
        arguments: [String: Any] = [:],
        content: Data? = nil,
        contentType: String? = nil) async throws -> T {
        return try await invoke(method, path: path,
            arguments: arguments,
            content: content,
            contentType: contentType) { content, _ in try WebServiceProxy.jsonDecoder.decode(T.self, from: content) }
    }

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter arguments: The request arguments.
     - parameter body: The request body.
     - returns The response body.
     */
    public func invoke<B: Encodable, T: Decodable>(_ method: Method, path: String,
        arguments: [String: Any] = [:],
        body: B) async throws -> T {
        return try await invoke(method, path: path,
            arguments: arguments,
            content: try WebServiceProxy.jsonEncoder.encode(body),
            contentType: WebServiceProxy.applicationJSON)
    }

    /**
     Invokes a service operation.
     - parameter method: The HTTP method.
     - parameter path: The path to the resource, relative to the base URL.
     - parameter arguments: The request arguments.
     - parameter content: The request content, or `nil` for no content.
     - parameter contentType: The request content type, or `nil` for no content type.
     - parameter responseHandler: A callback that will be invoked to handle the response.
     - returns The response body.
     */
    public func invoke<T>(_ method: Method, path: String,
        arguments: [String: Any] = [:],
        content: Data? = nil,
        contentType: String? = nil,
        responseHandler: @escaping ResponseHandler<T>) async throws -> T {
        var urlQueryItems: [URLQueryItem] = []

        for argument in arguments {
            if (argument.key.isEmpty) {
                throw WebServiceError(errorDescription: "Invalid key.", statusCode: 0)
            }

            for element in argument.value as? [Any] ?? [argument.value] {
                if (element is NSNull) {
                    continue
                }

                let value: String
                if let date = element as? Date {
                    value = String(describing: Int64(date.timeIntervalSince1970 * 1000))
                } else {
                    value = String(describing: element)
                }

                urlQueryItems.append(URLQueryItem(name: argument.key, value: value))
            }
        }

        var urlComponents = URLComponents()

        urlComponents.queryItems = urlQueryItems

        let query = urlComponents.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") ?? ""

        let url: URL?
        if (query.isEmpty) {
            url = URL(string: path, relativeTo: baseURL)
        } else {
            url = URL(string: path + "?" + query, relativeTo: baseURL)
        }

        if (url == nil) {
            throw WebServiceError(errorDescription: "Invalid path.", statusCode: 0)
        }
        
        var urlRequest = URLRequest(url: url!)

        urlRequest.httpMethod = method.rawValue

        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if (content != nil) {
            urlRequest.setValue(contentType ?? "application/octet-stream", forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = content

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
            if (contentType?.lowercased().hasPrefix("text/plain") ?? false) {
                errorDescription = String(data: content, encoding: .utf8)
            } else {
                errorDescription = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            }

            throw WebServiceError(errorDescription: errorDescription, statusCode: statusCode)
        }
    }
}
