import XCTest
@testable import Kilo

final class KiloTests: XCTestCase {
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
    
    let timeout = 10.0
    
    static var webServiceProxy: WebServiceProxy!
    
    override class func setUp() {
        let sessionConfiguration = URLSessionConfiguration.default

        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        sessionConfiguration.timeoutIntervalForResource = 4

        let session = URLSession(configuration: sessionConfiguration)

        guard let baseURL = URL(string: "http://localhost:8080/httprpc-test-1.0/") else {
            XCTFail()
            return
        }
        
        webServiceProxy = WebServiceProxy(session: session, baseURL: baseURL)
    }
    
    func testGet() {
        var valid: Bool!
        let expectation = self.expectation(description: "GET")
        
        let now = Date(timeIntervalSince1970: TimeInterval(UInt64(Date().timeIntervalSince1970 * 1000)))

        KiloTests.webServiceProxy.invoke(.get, path: "test", arguments: [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now
        ]) { (result: Result<Response, Error>) in
            switch (result) {
            case .success(let value):
                valid = (value.string == "héllo&gøod+bye?"
                    && value.strings == ["a", "b", "c"]
                    && value.number == 123
                    && value.flag == true
                    && value.date == now
                    && value.attachmentInfo == nil)

            case .failure(let error):
                print(error.localizedDescription)
                valid = false
            }

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testGetFibonacci() {
        var valid: Bool!
        let expectation = self.expectation(description: "GET (Fibonacci)")

        KiloTests.webServiceProxy.invoke(.get, path: "test/fibonacci", arguments: [
            "count": 8
        ]) { (result: Result<[Int], Error>) in
            switch (result) {
            case .success(let value):
                valid = (value == [0, 1, 1, 2, 3, 5, 8, 13])

            case .failure(let error):
                print(error.localizedDescription)
                valid = false
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testURLEncodedPost() {
        var valid: Bool!
        let expectation = self.expectation(description: "POST (URL-encoded)")
        
        let now = Date(timeIntervalSince1970: TimeInterval(UInt64(Date().timeIntervalSince1970 * 1000)))

        KiloTests.webServiceProxy.encoding = .applicationXWWWFormURLEncoded
        
        KiloTests.webServiceProxy.invoke(.post, path: "test", arguments: [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now
        ]) { (result: Result<Response, Error>) in
            switch (result) {
            case .success(let value):
                valid = (value.string == "héllo&gøod+bye?"
                    && value.strings == ["a", "b", "c"]
                    && value.number == 123
                    && value.flag == true
                    && value.date == now
                    && value.attachmentInfo == [])

            case .failure(let error):
                print(error.localizedDescription)
                valid = false
            }

            expectation.fulfill()
        }
    
        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testMultipartPost() {
        var valid: Bool!
        let expectation = self.expectation(description: "POST (multipart)")

        let now = Date(timeIntervalSince1970: TimeInterval(UInt64(Date().timeIntervalSince1970 * 1000)))
        
        let fileURL = URL(fileURLWithPath: #file)
        let testTextURL = URL(fileURLWithPath: "test.txt", relativeTo: fileURL)
        let testImageURL = URL(fileURLWithPath: "test.jpg", relativeTo: fileURL)
                
        KiloTests.webServiceProxy.encoding = .multipartFormData

        KiloTests.webServiceProxy.invoke(.post, path: "test", arguments: [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now,
            "attachments": [testTextURL, testImageURL]
        ]) { (result: Result<Response, Error>) in
            switch (result) {
            case .success(let value):
                valid = (value.string == "héllo&gøod+bye?"
                    && value.strings == ["a", "b", "c"]
                    && value.number == 123
                    && value.flag == true
                    && value.date == now
                    && value.attachmentInfo == [
                        AttachmentInfo(bytes: 26, checksum: 2412),
                        AttachmentInfo(bytes: 10392, checksum: 1038036)
                    ])

            case .failure(let error):
                print(error.localizedDescription)
                valid = false
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testCustomBodyPost() {
        var valid: Bool!
        let expectation = self.expectation(description: "POST (custom body)")

        let body: [String: Any] = [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true
        ]

        guard let content = try? JSONSerialization.data(withJSONObject: body) else {
            XCTFail()
            return
        }
        
        KiloTests.webServiceProxy.invoke(.post, path: "test", arguments: [
            "id": 101
        ], content: content, contentType: "application/json") { (result: Result<Body, Error>) in
            switch (result) {
            case .success(let value):
                valid = (value.string == body["string"] as? String
                    && value.strings == body["strings"] as? [String]
                    && value.number == body["number"] as? Int
                    && value.flag == body["flag"] as? Bool)

            case .failure(let error):
                print(error.localizedDescription)
                valid = false
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testCustomImagePost() {
        var valid: Bool!
        let expectation = self.expectation(description: "POST (custom image)")

        let fileURL = URL(fileURLWithPath: #file)
        let testImageURL = URL(fileURLWithPath: "test.jpg", relativeTo: fileURL)

        KiloTests.webServiceProxy.invoke(.post, path: "test", arguments: [
            "name": testImageURL.lastPathComponent
        ], content: try? Data(contentsOf: testImageURL), responseHandler: { content, contentType in
            return content
        }) { (result: Result<Data?, Error>) in
            switch (result) {
            case .success(let value):
                valid = (value != nil)

            case .failure(let error):
                print(error.localizedDescription)
                valid = false
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testPut() {
        var valid: Bool!
        let expectation = self.expectation(description: "PUT")
        
        let fileURL = URL(fileURLWithPath: #file)
        let testTextURL = URL(fileURLWithPath: "test.txt", relativeTo: fileURL)

        KiloTests.webServiceProxy.invoke(.put, path: "test", arguments: [
            "id": 101
        ], content: try? Data(contentsOf: testTextURL), contentType: "text/plain", responseHandler: { content, contentType in
            return String(data: content, encoding: .utf8)
        }) { (result: Result<String?, Error>) in
            switch (result) {
            case .success(let value):
                valid = (value != nil)

            case .failure(let error):
                print(error.localizedDescription)
                valid = false
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testDelete() {
        var valid: Bool!
        let expectation = self.expectation(description: "DELETE")

        KiloTests.webServiceProxy.invoke(.delete, path: "test", arguments: [
            "id": 101
        ]) { (result: Result<Void, Error>) in
            switch (result) {
            case .success:
                valid = true

            case .failure(let error):
                print(error.localizedDescription)
                valid = false
            }

            expectation.fulfill()
        }
    
        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testUnauthorized() {
        var valid: Bool!
        let expectation = self.expectation(description: "Unauthorized")

        KiloTests.webServiceProxy.invoke(.get, path: "test/unauthorized") { (result: Result<Void, Error>) in
            switch (result) {
            case .failure(let error):
                print(error.localizedDescription)
                valid = (error as? WebServiceError)?.statusCode == 403

            default:
                valid = false
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testError() {
        var valid: Bool!
        let expectation = self.expectation(description: "Error")

        KiloTests.webServiceProxy.invoke(.get, path: "test/error") { (result: Result<Void, Error>) in
            switch (result) {
            case .failure(let error):
                print(error.localizedDescription)
                valid = true

            default:
                valid = false
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testTimeout() {
        var valid: Bool!
        let expectation = self.expectation(description: "Timeout")

        KiloTests.webServiceProxy.invoke(.get, path: "test", arguments: [
            "value": 123,
            "delay": 6000
        ]) { (result: Result<Int, Error>) in
            switch (result) {
            case .failure(let error):
                print(error.localizedDescription)
                valid = true

            default:
                valid = false
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
    
    func testCatalog() {
        var valid: Bool!
        let expectation = self.expectation(description: "Catalog")

        do {
            try KiloTests.webServiceProxy.invoke(.post, path: "catalog/items",
                body: Item(id: nil, description: "abc", price: 150.00)) { (result: Result<Item, Error>) in
                switch (result) {
                case .success(let item):
                    if let itemID = item.id, item.description == "abc" && item.price == 150.00 {
                        do {
                            try KiloTests.webServiceProxy.invoke(.put, path: "catalog/items/\(itemID)",
                                body: Item(id: item.id, description: "xyz", price: 300.00)) { (result: Result<Void, Error>) in
                                switch (result) {
                                case .success:
                                    KiloTests.webServiceProxy.invoke(.delete, path: "catalog/items/\(itemID)") { (result: Result<Void, Error>) in
                                        switch (result) {
                                        case .success:
                                            valid = true
                                        
                                        case .failure(let error):
                                            print(error.localizedDescription)
                                            valid = false
                                        }
                                        
                                        expectation.fulfill()
                                    }
                                
                                case .failure(let error):
                                    print(error.localizedDescription)
                                    valid = false
                                    
                                    expectation.fulfill()
                                }
                            }
                        } catch {
                            valid = false
                            
                            expectation.fulfill()
                        }
                    } else {
                        valid = false
                    
                        expectation.fulfill()
                    }
                
                case .failure(let error):
                    print(error.localizedDescription)
                    valid = false
                    
                    expectation.fulfill()
                }
            }
        } catch {
            valid = false
            
            expectation.fulfill()
        }

        waitForExpectations(timeout: timeout)
        
        XCTAssert(valid)
    }
}
