[![Releases](https://img.shields.io/github/release/gk-brown/Kilo.svg)](https://github.com/gk-brown/Kilo/releases)
[![CocoaPods](https://img.shields.io/cocoapods/v/Kilo.svg)](https://cocoapods.org/pods/Kilo)
[![Maven Central](https://img.shields.io/maven-central/v/org.gkbrown/kilo.svg)](http://repo1.maven.org/maven2/org/gkbrown/kilo/)

# Introduction
Kilo is an open-source framework for consuming REST services in iOS/tvOS and Android. It is extremely lightweight and provides a simple, intuitive API that makes it easy to interact with services regardless of target device or operating system. 

The project's name comes from the nautical _K_ or _Kilo_ flag, which means "I wish to communicate with you":

![](README/kilo.png)

This guide introduces the Kilo framework and provides an overview of its key features.

# Feedback
Feedback is welcome and encouraged. Please feel free to [contact me](mailto:gk_brown@icloud.com?subject=Kilo) with any questions, comments, or suggestions. Also, if you like using Kilo, please consider [starring](https://github.com/gk-brown/Kilo/stargazers) it!

# Contents
* [Getting Kilo](#getting-kilo)
* [iOS/tvOS](#ios/tvos)
* [Android](#android)
* [Additional Information](#additional-information)

# Getting Kilo
The iOS/tvOS version of Kilo is distributed as a universal binary that will run in the simulator as well as on an actual device. It is also available via [CocoaPods](https://cocoapods.org/pods/Kilo). Either iOS 10 or tvOS 10 or later is required. 

To install:

* Download the [latest release](https://github.com/gk-brown/Kilo/releases) archive and expand
* In Xcode, select the project root node in the Project Navigator view
* Select the application target
* Select the "General" tab
* Drag _Kilo.framework_ to the "Embedded Binaries" section
* In the dialog that appears, ensure that "Copy items if needed" is checked and click "Finish"

Note that the framework binary must be "trimmed" prior to App Store submission. See the [Deployment](#deployment) section for more information.

The Android version can be downloaded [here](https://github.com/gk-brown/Kilo/releases). It is also available via Maven:

```xml
<dependency>
    <groupId>org.gkbrown</groupId>
    <artifactId>kilo</artifactId>
    <version>...</version>
</dependency>
```

Java 8 or later is required.

# iOS/tvOS
The iOS/tvOS version of the Kilo framework contains a single class named `WebServiceProxy` that is used to issue API requests to the server. Service proxies are initialized via the `init(session:serverURL:)` method, which takes the following arguments:

* `session` - a `URLSession` instance
* `serverURL` - the base URL of the service

A service operation is initiated via one of the following methods:

```swift
public func invoke<T>(_ method: Method, path: String,
    arguments: [String: Any] = [:], 
    content: Data? = nil, contentType: String? = nil,
    resultHandler: @escaping (_ result: T?, _ error: Error?) -> Void) -> URLSessionTask? { ... }

public func invoke<T: Decodable>(_ method: Method, path: String,
    arguments: [String: Any] = [:], 
    content: Data? = nil, contentType: String? = nil,
    resultHandler: @escaping (_ result: T?, _ error: Error?) -> Void) -> URLSessionTask? { ... }

public func invoke<T>(_ method: Method, path: String,
    arguments: [String: Any] = [:], 
    content: Data? = nil, contentType: String? = nil,
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

The first version of the method uses `JSONSerialization` to decode response data. The second uses `JSONDecoder` with a date decoding strategy of `millisecondsSince1970`. The third version accepts an additional `responseHandler` argument to facilitate decoding of custom response content (for example, a `UIImage`).

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
The following Swift code demonstrates how the `WebServiceProxy` class might be used to access a service that returns the first _n_ values in the Fibonacci sequence:

```swift
let webServiceProxy = WebServiceProxy(session: URLSession.shared, serverURL: serverURL)

// GET test/fibonacci?count=8
webServiceProxy.invoke(.get, path: "test/fibonacci", arguments: [
    "count": 8
]) { (result: [Int]?, error: Error?) in
    // [0, 1, 1, 2, 3, 5, 8, 13]
}
```

## Deployment
The Kilo framework is a universal binary that must be "trimmed" prior to submission to the App Store:

* Place the _[trim.sh](Xcode/trim.sh)_ script in your project root directory
* Ensure that the script has execute permission (e.g. 744)
* Create a new "Run Script" build phase after the "Embed Frameworks" phase
* Rename the new build phase to "Trim Framework Executables" or similar (optional)
* Invoke the script (e.g. `"${SRCROOT}/trim.sh" Kilo`)

# Android
Like the iOS/tvOS version, the Android version of the Kilo framework includes a `WebServiceProxy` class that is used to issue API requests to the server. Additionally, the `WebServiceException` class is provided to represent HTTP errors returned by a service.

Service proxies are initialized via a constructor that takes the following arguments:

* `method` - the HTTP method to execute
* `url` - an instance of `java.net.URL` representing the target of the operation

Request headers and arguments are specified via the `setHeaders()` and `setArguments()` methods, respectively. Like HTML forms, arguments are submitted either via the query string or in the request body. Arguments for `GET`, `PUT`, and `DELETE` requests are always sent in the query string. `POST` arguments are typically sent in the request body, and may be submitted as either "application/x-www-form-urlencoded" or "multipart/form-data" (specified via the proxy's `setEncoding()` method). However, if the request body is provided via a custom request handler (specified via the `setRequestHandler()` method), `POST` arguments will be sent in the query string.

The `toString()` method is generally used to convert an argument to its string representation. However, `Date` instances are automatically converted to a long value representing epoch time. Additionally, `Iterable` instances represent multi-value parameters and behave similarly to `<select multiple>` tags in HTML. Further, when using the multi-part encoding, `URL` and `Iterable<URL>` values represent file uploads, and behave similarly to `<input type="file">` tags in HTML forms.

Service operations are invoked via the following method. The provided `responseHandler` is used to deserialize the response returned by the server (for example, using the `ObjectMapper` class provided by the [Jackson](https://github.com/FasterXML/jackson) framework):

```java
public <T> T invoke(ResponseHandler<T> responseHandler) throws IOException { ... }
``` 

Unlike the iOS/tvOS version, the method is executed synchronously. As a result, service proxies should only be used on a background thread (for example, within an `AsyncTask` implementation).

If the server returns an error response, a `WebServiceException` will be thrown. The response code can be retrieved via the exception's `getStatus()` method. If the content type of the response is "text/plain", the body of the response will be returned in the exception message.

For example, the following Java code demonstrates how the `WebServiceProxy` class might be used to access the Fibonacci service discussed earlier:

```java
WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test/fibonacci"));

// GET test/fibonacci?count=8
webServiceProxy.setArguments(Collections.singletonMap("count", 8));

// [0, 1, 1, 2, 3, 5, 8, 13]
List<Integer> result = webServiceProxy.invoke((inputStream, contentType) -> new ObjectMapper().readValue(inputStream,
    new TypeReference<List<Integer>>(){}));
```

In Kotlin, the code might look like this:

```kotlin
val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test/fibonacci"))

// GET test/fibonacci?count=8
webServiceProxy.arguments = mapOf(
    "count" to 8
)

// [0, 1, 1, 2, 3, 5, 8, 13]
val result = webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, List::class.java) }
```

# Additional Information
This guide introduced the Kilo framework and provided an overview of its key features. For additional information, see the the [examples](https://github.com/gk-brown/Kilo/tree/master/).
