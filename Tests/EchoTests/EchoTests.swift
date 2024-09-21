import XCTest

@testable import Echo

final class EchoTests: XCTestCase {
    enum DayOfWeek: String, Codable, CustomStringConvertible {
        case monday = "MONDAY"
        case tuesday = "TUESDAY"
        case wednesday = "WEDNESDAY"
        case thursday = "THURSDAY"
        case friday = "FRIDAY"
        case saturday = "SATURDAY"
        case sunday = "SUNDAY"

        var description: String {
            return rawValue
        }
    }

    class Response: Decodable {
        let string: String
        let strings: [String]
        let number: Int
        let numbers: [Int]
        let dayOfWeek: DayOfWeek
        let flag: Bool
        let date: Date
        let dates: [Date]
    }

    struct Body: Codable {
        let string: String
        let strings: [String]
        let number: Int
        let numbers: [Int]
        let flag: Bool
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

        let result: Response = try await EchoTests.webServiceProxy.invoke(.get, path: "test", arguments: [
            "string": "héllo&gøod+bye?",
            "strings": ["a", "b", "c"],
            "number": 123,
            "numbers": [1, 2, 2, 3, 3, 3],
            "flag": true,
            "dayOfWeek": DayOfWeek.monday,
            "date": now,
            "dates": [now]
        ])

        XCTAssert(result.string == "héllo&gøod+bye?"
            && result.strings == ["a", "b", "c"]
            && result.number == 123
            && result.numbers == [1, 2, 3]
            && result.flag == true
            && result.dayOfWeek == .monday
            && result.date == now
            && result.dates == [now])
    }
    
    func testGetFibonacci() async throws {
        let result: [Int] = try await EchoTests.webServiceProxy.invoke(.get, path: "test/fibonacci", arguments: [
            "count": 8
        ])
        
        XCTAssert(result == [0, 1, 1, 2, 3, 5, 8, 13])
    }
    
    func testBodyPost() async throws {
        let body = Body(string: "héllo&gøod+bye?",
            strings: ["a", "b", "c"],
            number: 123,
            numbers: [1, 2, 2, 3, 3, 3],
            flag: true)

        let result: Body = try await EchoTests.webServiceProxy.invoke(.post, path: "test/body", body: body)

        XCTAssert(result.string == "héllo&gøod+bye?"
            && result.strings == ["a", "b", "c"]
            && result.number == 123
            && result.numbers == [1, 2, 3]
            && result.flag == true)
    }
    
    func testImagePost() async throws {
        let fileURL = URL(fileURLWithPath: #file)
        let testImageURL = URL(fileURLWithPath: "test.jpg", relativeTo: fileURL)

        let result: Data? = try await EchoTests.webServiceProxy.invoke(.post, path: "test/image",
            content: try? Data(contentsOf: testImageURL)) { content, contentType in
            return content
        }
        
        XCTAssert(result != nil)
    }
    
    func testPut() async throws {
        let fileURL = URL(fileURLWithPath: #file)
        let testTextURL = URL(fileURLWithPath: "test.txt", relativeTo: fileURL)

        let result: String? = try await EchoTests.webServiceProxy.invoke(.put, path: "test",
            content: try? Data(contentsOf: testTextURL)) { content, contentType in
            return String(data: content, encoding: .utf8)
        }
        
        XCTAssert(result != nil)
    }

    func testEmptyPut() async throws {
        let id = 101

        let result: Int? = try await EchoTests.webServiceProxy.invoke(.put, path: "test/\(id)", arguments: [
            "value": "abc"
        ])

        XCTAssert(result == id)
    }

    func testDelete() async throws {
        let id = 101

        let result: Int? = try await EchoTests.webServiceProxy.invoke(.delete, path: "test/\(id)")

        XCTAssert(result == id)
    }

    func testHeaders() async throws {
        EchoTests.webServiceProxy.headers = [
            "X-Header-A": "abc",
            "X-Header-B": "123",
        ]

        let result: [String: String]? = try await EchoTests.webServiceProxy.invoke(.get, path: "test/headers") { content, contentType in
            return try? JSONSerialization.jsonObject(with: content) as? [String: String]
        }

        XCTAssert(result != nil)

        XCTAssert(result?["X-Header-A"] == "abc")
        XCTAssert(result?["X-Header-B"] == "123")
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
}
