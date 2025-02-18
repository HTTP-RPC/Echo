[![Releases](https://img.shields.io/github/release/HTTP-RPC/Echo.svg)](https://github.com/HTTP-RPC/Echo/releases)

# Introduction
Echo is a Swift package for consuming RESTful and REST-like web services. It provides a lightweight, API-centric wrapper around the more general `URLSesssion` class provided by the Foundation framework. The project's name comes from the nautical _E_ or _Echo_ flag:

![](echo.png)

For example, the following code uses Echo's `WebServiceProxy` class to access a simple web service that returns the first _n_ values of the Fibonacci sequence:

```swift
let webServiceProxy = WebServiceProxy(session: URLSession.shared, baseURL: baseURL)

do {
    // GET test/fibonacci?count=8
    let response: [Int] = try await webServiceProxy.invoke(.get, path: "test/fibonacci", arguments: [
        "count": 8
    ])
    
    print(response) // [0, 1, 1, 2, 3, 5, 8, 13]
} catch {
    print(error.localizedDescription)
}
```

iOS 16 or later is required.

# WebServiceProxy
The `WebServiceProxy` class is used to issue API requests to the server. This class provides a single initializer that accepts the following arguments:

* `session` - a `URLSession` instance
* `baseURL` - the base URL of the service

Service operations are initiated via one of the following methods:

```swift
public func invoke(_ method: Method, path: String, 
    arguments: [String: Any] = [:],
    content: Data? = nil, 
    contentType: String? = nil) async throws { ... }

public func invoke<B: Encodable>(_ method: Method, path: String, 
    arguments: [String: Any] = [:], 
    body: B) async throws { ... }

public func invoke<T: Decodable>(_ method: Method, path: String,
    arguments: [String: Any] = [:],
    content: Data? = nil, 
    contentType: String? = nil) async throws -> T { ... }

public func invoke<B: Encodable, T: Decodable>(_ method: Method, path: String,
    arguments: [String: Any] = [:],
    body: B) async throws -> T { ... }

public func invoke<T>(_ method: Method, path: String,
    arguments: [String: Any] = [:],
    content: Data? = nil, 
    contentType: String? = nil,
    responseHandler: @escaping ResponseHandler<T>) async throws -> T { ... }
```

All variants accept the following arguments:

* `method` - the HTTP method to execute
* `path` - the path to the requested resource, relative to the base URL
* `arguments` - a dictionary containing the query arguments as name/value pairs

The first two versions execute a service method that does not return a value. The following two versions deserialize a service response of type `T` using `JSONDecoder`. The final version accepts a `ResponseHandler` callback to facilitate decoding of custom response content:

```swift
public typealias ResponseHandler<T> = (_ content: Data, _ contentType: String?) throws -> T
```

Three of the methods accept the following arguments for specifying custom request body content:

* `content` - an optional `Data` instance representing the body of the request
* `contentType` - an optional string value containing the MIME type of the content

The other two methods accept a `body` argument of type `B` that is serialized using `JSONEncoder`. JSON data is encoded and decoded using a date strategy of `millisecondsSince1970`.

## Query Arguments
Any value may be used as a query argument and will generally be encoded using its string representation. However, `Date` instances are first converted to a 64-bit integer value representing epoch time. Additionally, array instances represent multi-value parameters and behave similarly to `<select multiple>` tags in HTML forms.

The `undefined` property of the `WebServiceProxy` class can be used to represent unspecified or unknown argument values.

## Return Values
A value representing the server response is returned upon successful completion of an operation. If an operation does not complete successfully, a `WebServiceError` will be thrown. The error's `statusCode` property can be used to determine the nature of the error. If the type of the error response is "text/plain", the response content will be provided in the error's localized description:

```swift
if let webServiceError = error as? WebServiceError {
    print(webServiceError.statusCode)
}

print(error.localizedDescription)
```
