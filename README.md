[![Releases](https://img.shields.io/github/release/gk-brown/Kilo.svg)](https://github.com/gk-brown/Kilo/releases)
[![CocoaPods](https://img.shields.io/cocoapods/v/Kilo.svg)](https://cocoapods.org/pods/Kilo)
[![Maven Central](https://img.shields.io/maven-central/v/org.gkbrown/kilo.svg)](http://repo1.maven.org/maven2/org/gkbrown/kilo/)

# Introduction
Kilo is an open-source framework for consuming REST services in iOS/tvOS and Android. It is extremely lightweight and provides a simple, intuitive API that makes it easy to interact with services regardless of target device or operating system. 

The project's name comes from the nautical _K_ or _Kilo_ flag, which means "I wish to communicate with you":

![](README/kilo.png)

This guide introduces the Kilo framework and provides an overview of its key features.

# Contents
* [Getting Kilo](#getting-kilo)
* [iOS/tvOS](#ios/tvos)
* [Android](#android)
* [Additional Information](#additional-information)

# Getting Kilo
The iOS/tvOS version of the Kilo framework is distributed as a universal binary that will run in the simulator as well as on an actual device. It is also available via [CocoaPods](https://cocoapods.org/pods/Kilo). Either iOS 11 or tvOS 11 or later is required. 

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
The `WebServiceProxy` class is used to issue API requests to the server. This class provides a single initializer that accepts the following arguments:

* `session` - a `URLSession` instance
* `serverURL` - the base URL of the service

Service operations are initiated via one of the following methods:

```swift
public func invoke(_ method: Method, path: String,
    arguments: [String: Any] = [:],
    content: Data? = nil, contentType: String? = nil,
    resultHandler: @escaping ResultHandler<Void>) { ... }

public func invoke<T: Decodable>(_ method: Method, path: String,
    arguments: [String: Any] = [:],
    content: Data? = nil, contentType: String? = nil,
    resultHandler: @escaping ResultHandler<T>) { ... }

public func invoke<T>(_ method: Method, path: String,
    arguments: [String: Any] = [:],
    content: Data? = nil, contentType: String? = nil,
    responseHandler: @escaping ResponseHandler<T>,
    resultHandler: @escaping ResultHandler<T>) { ... }
```

All three variants accept the following arguments:

* `method` - the HTTP method to execute
* `path` - the path to the requested resource
* `arguments` - a dictionary containing the method arguments as key/value pairs
* `content` - an optional `Data` instance representing the body of the request
* `contentType` - an optional string value containing the MIME type of the content
* `resultHandler` - a callback that will be invoked upon completion of the request

The first version executes a service method that does not return a value. The second deserializes the response using `JSONDecoder`, with a date decoding strategy of `millisecondsSince1970`. The third version accepts an additional `responseHandler` argument to facilitate decoding of custom response content (for example, a `UIImage`).

Response and result handler callbacks are defined as follows:

```swift
public typealias ResponseHandler<T> = (_ content: Data, _ contentType: String?) throws -> T

public typealias ResultHandler<T> = (_ result: Result<T, Error>) -> Void
```

## Arguments
Like HTML forms, arguments are submitted either via the query string or in the request body. Arguments for `GET`, `PUT`, and `DELETE` requests are always sent in the query string. `POST` arguments are typically sent in the request body, and may be submitted as either "application/x-www-form-urlencoded" or "multipart/form-data" (determined via the service proxy's `encoding` property). However, if a custom body is specified via the `content` parameter, `POST` arguments will be sent in the query string.

Any value that provides a `description` property may be used as an argument. This property is generally used to convert the argument to its string representation. However, `Date` instances are automatically converted to a 64-bit integer value representing epoch time (the number of milliseconds that have elapsed since midnight on January 1, 1970).

Additionally, array instances represent multi-value parameters and behave similarly to `<select multiple>` tags in HTML. Further, when using the multi-part form data encoding, instances of `URL` represent file uploads and behave similarly to `<input type="file">` tags in HTML forms. Arrays of URL values operate similarly to `<input type="file" multiple>` tags.

## Return Values
The result handler is called upon completion of the operation. If successful, the first argument will contain a deserialized representation of the content returned by the server, and the second argument will be `nil`. Otherwise, the first argument will be `nil`, and the second will be populated with an `Error` instance describing the problem that occurred. 

If a service returns an error response with a content type of "text/plain", the body of the response will be provided in the error's localized description.

## Threading Considerations
While service requests are typically processed on a background thread, result handlers are always executed on the application's main thread. This allows a result handler to update the user interface directly, rather than posting a separate update operation to the main queue. Note that response handlers are executed in the background, before the result handler is invoked.

## Example
The following Swift code demonstrates how the `WebServiceProxy` class might be used to access a service that returns the first _n_ values in the Fibonacci sequence:

```swift
let webServiceProxy = WebServiceProxy(session: URLSession.shared, serverURL: serverURL)

// GET test/fibonacci?count=8
webServiceProxy.invoke(.get, path: "test/fibonacci", arguments: [
    "count": 8
]) { [weak self] (result: Result<[Int], Error>) in
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
The `WebServiceProxy` class is used to issue API requests to the server. This class provides a single constructor that accepts the following arguments:

* `method` - the HTTP method to execute
* `url` - the URL of the requested resource

Request headers and arguments are specified via the `setHeaders()` and `setArguments()` methods, respectively. Like HTML forms, arguments are submitted either via the query string or in the request body. Arguments for `GET`, `PUT`, and `DELETE` requests are always sent in the query string. `POST` arguments are typically sent in the request body, and may be submitted as either "application/x-www-form-urlencoded" or "multipart/form-data" (specified via the proxy's `setEncoding()` method). However, if the request body is provided via a custom request handler (specified via the `setRequestHandler()` method), `POST` arguments will be sent in the query string.

The `toString()` method is generally used to convert an argument to its string representation. However, `Date` instances are automatically converted to a long value representing epoch time. Additionally, `Iterable` instances represent multi-value parameters and behave similarly to `<select multiple>` tags in HTML. Further, when using the multi-part encoding, `URL` and `Iterable<URL>` values represent file uploads, and behave similarly to `<input type="file">` tags in HTML forms.

Service operations are initiated via one of the following methods:

```java
public void invoke() throws IOException { ... }

public <T> T invoke(ResponseHandler<T> responseHandler) throws IOException { ... }
``` 

The first version executes a service method that does not return a value. The second accepts a `responseHandler` callback that is used to deserialize the response returned by the server (for example, using the `ObjectMapper` class provided by the [Jackson](https://github.com/FasterXML/jackson) framework). 

`ResponseHandler` is a functional interface that is defined as follows:

```java
public interface ResponseHandler<T> {
    public T decodeResponse(InputStream inputStream, String contentType) throws IOException;
}
```

If a service returns an error response, an exception will be thrown. If the content type of the response is "text/plain", the body of the response will be provided in the exception message.

## Threading Considerations
`WebServiceProxy` executes service operations synchronously. As a result, service proxies should only be used on a background thread (for example, within an `AsyncTask` implementation).

## Example
The following Java code demonstrates how the `WebServiceProxy` class might be used to access a service that returns the first _n_ values in the Fibonacci sequence:

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
This guide introduced the Kilo framework and provided an overview of its key features. For additional information, see the [examples](https://github.com/gk-brown/Kilo/tree/master/).
