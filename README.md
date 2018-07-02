[![Releases](https://img.shields.io/github/release/gk-brown/Kilo.svg)](https://github.com/gk-brown/Kilo/releases)

# Introduction
Kilo is an open-source framework for consuming REST services in iOS or tvOS. It is extremely lightweight and provides a convenient, callback-based interface that makes it easy to interact with remote APIs.

For example, the following code snippet shows how a client application might access a simple service that returns a friendly greeting. The request is executed asynchronously, and the result is printed when the call returns:

```swift
webServiceProxy.invoke(.get, path: "/hello") { (result: String?, error: Error?) in
    if let greeting = result {
        print(greeting) // "Hello, World!"
    }
}
```

This guide introduces the Kilo framework and provides an overview of its key features.

# Feedback
Feedback is welcome and encouraged. Please feel free to [contact me](mailto:gk_brown@icloud.com?subject=Kilo) with any questions, comments, or suggestions. Also, if you like using Kilo, please consider [starring](https://github.com/gk-brown/Kilo/stargazers) it!

# Contents
* [Getting Kilo](#getting-kilo)
* [WebServiceProxy Class](#webserviceproxy-class)
* [Deployment](#deployment)
* [Additional Information](#additional-information)

# Getting Kilo
Kilo is distributed as a universal binary that will run in the iOS simulator as well as on an actual device. Either iOS 10 or tvOS 10 or later is required. 

To install:

* Download the [latest release](https://github.com/gk-brown/Kilo/releases) archive and expand
* In Xcode, select the project root node in the Project Navigator view
* Select the application target
* Select the "General" tab
* Drag _Kilo.framework_ to the "Embedded Binaries" section
* In the dialog that appears, ensure that "Copy items if needed" is checked and click "Finish"

Note that the framework binary must be "trimmed" prior to App Store submission. See the [Deployment](#deployment) section for more information.

# WebServiceProxy Class
The Kilo framework contains a single class named `WebServiceProxy` that is used to issue API requests to the server. Service proxies are initialized via `init(session:serverURL:)`, which takes the following arguments:

* `session` - a `URLSession` instance that is used to create service requests
* `serverURL` - the base URL of the service

A service operation is initiated via one of the following methods:

```swift
public func invoke<T>(_ method: Method, path: String,
    arguments: [String: Any] = [:], content: Data? = nil, contentType: String? = nil,
    resultHandler: @escaping (_ result: T?, _ error: Error?) -> Void) -> URLSessionTask? { ... }

public func invoke<T: Decodable>(_ method: Method, path: String,
    arguments: [String: Any] = [:], content: Data? = nil, contentType: String? = nil,
    resultHandler: @escaping (_ result: T?, _ error: Error?) -> Void) -> URLSessionTask? { ... }

public func invoke<T>(_ method: Method, path: String,
    arguments: [String: Any] = [:], content: Data? = nil, contentType: String? = nil,
    responseHandler: @escaping (_ content: Data, _ contentType: String?) throws -> T?,
    resultHandler: @escaping (_ result: T?, _ error: Error?) -> Void) -> URLSessionTask? { ... }
```

All three methods accept the following arguments:

* `method` - the HTTP method to execute
* `path` - the path to the requested resource
* `arguments` - a dictionary containing the method arguments as key/value pairs
* `content` - an optional `Data` instance representing the body of the request
* `contentType` - an optional string value containing the MIME type of the content
* `resultHandler` - a callback that will be invoked upon completion of the method

The first method uses `JSONSerialization` to decode response data, and the second uses `JSONDecoder` to return a decodable value. The third version accepts an additional `responseHandler` argument to facilitate decoding of custom response content (for example, a `UIImage`).

All three methods return an instance of `URLSessionTask` representing the invocation request. This allows an application to cancel a task, if necessary.

## Arguments
Like HTML forms, arguments are submitted either via the query string or in the request body. Arguments for `GET`, `PUT`, `PATCH`, and `DELETE` requests are always sent in the query string. 

`POST` arguments are typically sent in the request body, and may be submitted as either "application/x-www-form-urlencoded" or "multipart/form-data" (determined via the service proxy's `encoding` property). However, if a custom body is specified via the `content` parameter, `POST` arguments will be sent in the query string.

Any value that provides a `description` property may be used as an argument. This property is generally used to convert the argument to its string representation. However, `Date` instances are automatically converted to a 64-bit integer value representing epoch time (the number of milliseconds that have elapsed since midnight on January 1, 1970).

Additionally, array instances represent multi-value parameters and behave similarly to `<select multiple>` tags in HTML. Further, when using the multi-part form data encoding, instances of `URL` represent file uploads and behave similarly to `<input type="file">` tags in HTML forms. Arrays of URL values operate similarly to `<input type="file" multiple>` tags.

## Return Values
The result handler is called upon completion of the operation. If successful, the first argument will contain a deserialized representation of the content returned by the server, and the second argument will be `nil`. Otherwise, the first argument will be `nil`, and the second will be populated with an `Error` instance describing the problem that occurred.

Note that, while service requests are typically processed on a background thread, result handlers are always executed on the application's main thread. This allows result handlers to update the user interface directly, rather than posting a separate update operation to the main queue. Note that custom response handlers are executed on the request handler queue, before the result handler is invoked.

If the server returns an error response, a localized description of the error will be provided in the localized description of the error parameter. Further, if the error is returned with a content type of "text/plain", the response body will be returned in the error's debug description.

## Example
The following code snippet demonstrates how the `WebServiceProxy` class might be used to access the operations of a hypothetical math service:

```swift
// Create service proxy
let webServiceProxy = WebServiceProxy(session: URLSession.shared, serverURL: URL(string: "http://localhost:8080")!)

// Get sum of "a" and "b"
webServiceProxy.invoke(.get, path: "/math/sum", arguments: [
    "a": 2,
    "b": 4
]) { (result: Int?, error: Error?) in
    // result is 6
}

// Get sum of all values
webServiceProxy.invoke(.get, path: "/math/sum", arguments: [
    "values": [1, 2, 3, 4]
]) { (result: Int?, error: Error?) in
    // result is 10
}
```

# Deployment
The Kilo framework is a universal binary that must be "trimmed" prior to submission to the App Store:

* Place the _[trim.sh](Xcode/trim.sh)_ script in your project root directory
* Ensure that the script has execute permission (e.g. 744)
* Create a new "Run Script" build phase after the "Embed Frameworks" phase
* Rename the new build phase to "Trim Framework Executables" or similar (optional)
* Invoke the script (e.g. `"${SRCROOT}/trim.sh" Kilo`)

# Additional Information
This guide introduced the Kilo framework and provided an overview of its key features. For additional information, see the the [examples](https://github.com/gk-brown/Kilo/tree/development/Kilo-iOS/KiloTest).
