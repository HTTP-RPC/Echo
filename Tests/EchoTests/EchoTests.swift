import XCTest
@testable import Echo

final class EchoTests: XCTestCase {
    struct Response: Decodable {
        let string: String
        let strings: [String]
        let number: Int
        let flag: Bool
        let date: Date
        let attachmentInfo: [AttachmentInfo]?
    }

    struct AttachmentInfo: Decodable, Equatable {
        let bytes: Int
        let checksum: Int
    }
    
    struct Body: Decodable {
        let string: String
        let strings: [String]
        let number: Int
        let flag: Bool
    }
    
    struct Item: Codable {
        let id: Int?
        var description: String
        var price: Double
    }
    
    static var webServiceProxy: WebServiceProxy!
    
    override class func setUp() {
        let sessionConfiguration = URLSessionConfiguration.default

        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        sessionConfiguration.timeoutIntervalForResource = 4

        let session = URLSession(configuration: sessionConfiguration)

        guard let baseURL = URL(string: "http://localhost:8080/kilo-test/") else {
            XCTFail()
            return
        }
        
        webServiceProxy = WebServiceProxy(session: session, baseURL: baseURL)
    }
    
    func testGet() async throws {
        let now = Date(timeIntervalSince1970: TimeInterval(UInt64(Date().timeIntervalSince1970 * 1000)))

        let response: Response = try await EchoTests.webServiceProxy.invoke(.get, path: "test", arguments: [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now
        ])

        XCTAssert(response.string == "héllo&gøod+bye?"
            && response.strings == ["a", "b", "c"]
            && response.number == 123
            && response.flag == true
            && response.date == now
            && response.attachmentInfo == nil)
    }
    
    func testGetFibonacci() async throws {
        let response: [Int] = try await EchoTests.webServiceProxy.invoke(.get, path: "test/fibonacci", arguments: [
            "count": 8
        ])
        
        XCTAssert(response == [0, 1, 1, 2, 3, 5, 8, 13])
    }
    
    func testURLEncodedPost() async throws {
        let now = Date(timeIntervalSince1970: TimeInterval(UInt64(Date().timeIntervalSince1970 * 1000)))

        EchoTests.webServiceProxy.encoding = .applicationXWWWFormURLEncoded
        
        let response: Response = try await EchoTests.webServiceProxy.invoke(.post, path: "test", arguments: [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now
        ])
        
        XCTAssert(response.string == "héllo&gøod+bye?"
            && response.strings == ["a", "b", "c"]
            && response.number == 123
            && response.flag == true
            && response.date == now
            && response.attachmentInfo == [])
    }
    
    func testMultipartPost() async throws {
        let now = Date(timeIntervalSince1970: TimeInterval(UInt64(Date().timeIntervalSince1970 * 1000)))
        
        let fileURL = URL(fileURLWithPath: #file)
        let testTextURL = URL(fileURLWithPath: "test.txt", relativeTo: fileURL)
        let testImageURL = URL(fileURLWithPath: "test.jpg", relativeTo: fileURL)
                
        EchoTests.webServiceProxy.encoding = .multipartFormData

        let response: Response = try await EchoTests.webServiceProxy.invoke(.post, path: "test", arguments: [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now,
            "attachments": [testTextURL, testImageURL]
        ])
        
        XCTAssert(response.string == "héllo&gøod+bye?"
            && response.strings == ["a", "b", "c"]
            && response.number == 123
            && response.flag == true
            && response.date == now
            && response.attachmentInfo == [
                AttachmentInfo(bytes: 26, checksum: 2412),
                AttachmentInfo(bytes: 10392, checksum: 1038036)
            ])
    }
    
    func testCustomBodyPost() async throws {
        let request: [String: Any] = [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true
        ]

        guard let content = try? JSONSerialization.data(withJSONObject: request) else {
            XCTFail()
            return
        }
        
        let response: Body = try await EchoTests.webServiceProxy.invoke(.post, path: "test", arguments: [
            "id": 101
        ], content: content, contentType: "application/json")
        
        XCTAssert(response.string == request["string"] as? String
            && response.strings == request["strings"] as? [String]
            && response.number == request["number"] as? Int
            && response.flag == request["flag"] as? Bool)
    }
    
    func testCustomImagePost() async throws {
        let fileURL = URL(fileURLWithPath: #file)
        let testImageURL = URL(fileURLWithPath: "test.jpg", relativeTo: fileURL)

        let response: Data? = try await EchoTests.webServiceProxy.invoke(.post, path: "test", arguments: [
            "name": testImageURL.lastPathComponent
        ], content: try? Data(contentsOf: testImageURL), responseHandler: { content, contentType in
            return content
        })
        
        XCTAssert(response != nil)
    }
    
    func testPut() async throws {
        let fileURL = URL(fileURLWithPath: #file)
        let testTextURL = URL(fileURLWithPath: "test.txt", relativeTo: fileURL)

        let response: String? = try await EchoTests.webServiceProxy.invoke(.put, path: "test", arguments: [
            "id": 101
        ], content: try? Data(contentsOf: testTextURL), contentType: "text/plain", responseHandler: { content, contentType in
            return String(data: content, encoding: .utf8)
        })
        
        XCTAssert(response != nil)
    }
    
    func testDelete() async throws {
        try await EchoTests.webServiceProxy.invoke(.delete, path: "test", arguments: [
            "id": 101
        ])
        
        XCTAssert(true)
    }

    func testHeaders() async throws {
        EchoTests.webServiceProxy.headers = [
            "X-Header-A": "xyz"
        ]

        let response: [String: String]? = try await EchoTests.webServiceProxy.invoke(.get, path: "test/headers", headers: [
            "X-Header-A": "abc",
            "X-Header-B": "123"
        ], responseHandler: { content, contentType in
            return try? JSONSerialization.jsonObject(with: content) as? [String: String]
        })

        XCTAssert(response != nil)

        XCTAssert(response?["X-Header-A"] == "abc")
        XCTAssert(response?["X-Header-B"] == "123")
    }

    func testUnauthorized() async {
        do {
            try await EchoTests.webServiceProxy.invoke(.get, path: "test/unauthorized")
            
            XCTFail()
        } catch {
            guard let webServiceError = error as? WebServiceError else {
                XCTFail()
                return
            }
            
            XCTAssert(webServiceError.statusCode == 403)
        }
    }
    
    func testError() async throws {
        do {
            try await EchoTests.webServiceProxy.invoke(.get, path: "test/error")
            
            XCTFail()
        } catch {
            print(error.localizedDescription)
            
            XCTAssert(true)
        }
    }
    
    func testTimeout() async throws {
        do {
            try await EchoTests.webServiceProxy.invoke(.get, path: "test", arguments: [
                "value": 123,
                "delay": 6000
            ])
            
            XCTFail()
        } catch {
            print(error.localizedDescription)
            
            XCTAssert(true)
        }
    }

    func testMath1() async throws {
        let result: Double = try await EchoTests.webServiceProxy.invoke(.get, path: "test/math/sum", arguments: [
            "a": 4,
            "b": 2
        ])

        XCTAssert(result == 6.0)
    }

    func testMath2() async throws {
        let result: Double = try await EchoTests.webServiceProxy.invoke(.get, path: "test/math/sum", arguments: [
            "values": [1, 2, 3]
        ])

        XCTAssert(result == 6.0)
    }

    func testCatalog() async throws {
        let item: Item = try await EchoTests.webServiceProxy.invoke(.post, path: "catalog/items",
            body: Item(id: nil, description: "abc", price: 150.00))
            
        guard let itemID = item.id, item.description == "abc" && item.price == 150.00 else {
            XCTFail()
            return
        }
        
        try await EchoTests.webServiceProxy.invoke(.put, path: "catalog/items/\(itemID)",
            body: Item(id: item.id, description: "xyz", price: 300.00))
            
        try await EchoTests.webServiceProxy.invoke(.delete, path: "catalog/items/\(itemID)")
        
        XCTAssert(true)
    }
}
