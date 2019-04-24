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

import UIKit
import Kilo
import Lima

class ViewController: UITableViewController {
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

    var getCell: UITableViewCell!
    var getFibonacciCell: UITableViewCell!
    var postURLEncodedCell: UITableViewCell!
    var postMultipartCell: UITableViewCell!
    var postCustomCell: UITableViewCell!
    var putCell: UITableViewCell!
    var patchCell: UITableViewCell!
    var unauthorizedCell: UITableViewCell!
    var deleteCell: UITableViewCell!
    var timeoutCell: UITableViewCell!
    var cancelCell: UITableViewCell!
    var errorCell: UITableViewCell!

    var cells: [UITableViewCell]!

    override func loadView() {
        super.loadView()

        cells = [
            UITableViewCell(style: .value1, text: "GET") { self.getCell = $0 },
            UITableViewCell(style: .value1, text: "GET (Fibonacci)") { self.getFibonacciCell = $0 },
            UITableViewCell(style: .value1, text: "POST (URL-encoded)") { self.postURLEncodedCell = $0 },
            UITableViewCell(style: .value1, text: "POST (multipart)") { self.postMultipartCell = $0 },
            UITableViewCell(style: .value1, text: "POST (custom)") { self.postCustomCell = $0 },
            UITableViewCell(style: .value1, text: "PUT") { self.putCell = $0 },
            UITableViewCell(style: .value1, text: "DELETE") { self.deleteCell = $0 },
            UITableViewCell(style: .value1, text: "Unauthorized") { self.unauthorizedCell = $0 },
            UITableViewCell(style: .value1, text: "Error") { self.errorCell = $0 },
            UITableViewCell(style: .value1, text: "Cancel") { self.cancelCell = $0 },
            UITableViewCell(style: .value1, text: "Timeout") { self.timeoutCell = $0 }
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Kilo Test"

        // Configure session
        let sessionConfiguration = URLSessionConfiguration.default

        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        sessionConfiguration.timeoutIntervalForResource = 4

        // Create web service proxy
        let session = URLSession(configuration: sessionConfiguration)

        let hostname = UserDefaults.standard.string(forKey: "hostname") ?? "localhost"

        guard let serverURL = URL(string: "http://\(hostname):8080/httprpc-test/") else {
            return
        }

        let webServiceProxy = WebServiceProxy(session: session, serverURL: serverURL)

        let now = Date(timeIntervalSince1970: TimeInterval(UInt64(Date().timeIntervalSince1970 * 1000)))

        let testTextURL = Bundle.main.url(forResource: "test", withExtension: "txt")!
        let testImageURL = Bundle.main.url(forResource: "test", withExtension: "jpg")!

        // GET
        webServiceProxy.invoke(.get, path: "test", arguments: [
            "string": "héllo+gøodbye",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now
        ]) { [weak self] (result: Result<Response, Error>) in
            let valid: Bool
            switch (result) {
            case .success(let value):
                valid = (value.string == "héllo+gøodbye"
                    && value.strings == ["a", "b", "c"]
                    && value.number == 123
                    && value.flag == true
                    && value.date == now
                    && value.attachmentInfo == nil)

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.getCell)
        }

        // GET (Fibonacci)
        webServiceProxy.invoke(.get, path: "test/fibonacci", arguments: [
            "count": 8
        ]) { [weak self] (result: Result<[Int], Error>) in
            let valid: Bool
            switch (result) {
            case .success(let value):
                valid = (value == [0, 1, 1, 2, 3, 5, 8, 13])

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.getFibonacciCell)
        }

        // POST (URL-encoded)
        webServiceProxy.invoke(.post, path: "test", arguments: [
            "string": "héllo+gøodbye",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now
        ]) { [weak self] (result: Result<Response, Error>) in
            let valid: Bool
            switch (result) {
            case .success(let value):
                valid = (value.string == "héllo+gøodbye"
                    && value.strings == ["a", "b", "c"]
                    && value.number == 123
                    && value.flag == true
                    && value.date == now
                    && value.attachmentInfo == [])

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.postURLEncodedCell)
        }

        // POST (multi-part)
        webServiceProxy.encoding = .multipartFormData

        webServiceProxy.invoke(.post, path: "test", arguments: [
            "string": "héllo+gøodbye",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "date": now,
            "attachments": [testTextURL, testImageURL]
        ]) { [weak self] (result: Result<Response, Error>) in
            let valid: Bool
            switch (result) {
            case .success(let value):
                valid = (value.string == "héllo+gøodbye"
                    && value.strings == ["a", "b", "c"]
                    && value.number == 123
                    && value.flag == true
                    && value.date == now
                    && value.attachmentInfo == [
                        AttachmentInfo(bytes: 26, checksum: 2412),
                        AttachmentInfo(bytes: 10392, checksum: 1038036)
                    ])

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.postMultipartCell)
        }

        // POST (custom)
        webServiceProxy.invoke(.post, path: "test", arguments: [
            "name": testImageURL.lastPathComponent
        ], content: try? Data(contentsOf: testImageURL), responseHandler: { content, contentType in
            return UIImage(data: content)
        }) { [weak self] (result: Result<UIImage?, Error>) in
            let valid: Bool
            switch (result) {
            case .success(let value):
                valid = (value != nil)

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.postCustomCell)
        }

        // PUT
        webServiceProxy.invoke(.put, path: "test", arguments: [
            "id": 101
        ], content: try? Data(contentsOf: testTextURL), contentType: "text/plain", responseHandler: { content, contentType in
            return String(data: content, encoding: .utf8)
        }) { [weak self] (result: Result<String?, Error>) in
            let valid: Bool
            switch (result) {
            case .success(let value):
                valid = (value != nil)

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.putCell)
        }

        // DELETE
        webServiceProxy.invoke(.delete, path: "test", arguments: [
            "id": 101
        ]) { [weak self] (result: Result<Void, Error>) in
            let valid: Bool
            switch (result) {
            case .success:
                valid = true

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.deleteCell)
        }

        // Unauthorized
        webServiceProxy.invoke(.get, path: "test/unauthorized") { [weak self] (result: Result<Void, Error>) in
            let valid: Bool
            switch (result) {
            case .failure(let error):
                valid = (error as? WebServiceError)?.statusCode == 403

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.unauthorizedCell)
        }

        // Error
        webServiceProxy.invoke(.get, path: "test/error") { [weak self] (result: Result<Void, Error>) in
            let valid: Bool
            switch (result) {
            case .failure(let error):
                valid = true

                print(error.localizedDescription)

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.errorCell)
        }

        // Cancel
        let task = webServiceProxy.invoke(.get, path: "test", arguments: [
            "value": 123,
            "delay": 6000
        ]) { [weak self] (result: Result<Void, Error>) in
            let valid: Bool
            switch (result) {
            case .failure:
                valid = true

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.cancelCell)
        }

        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            task?.cancel()
        }

        // Timeout
        webServiceProxy.invoke(.get, path: "test", arguments: [
            "value": 123,
            "delay": 6000
        ]) { [weak self] (result: Result<Void, Error>) in
            let valid: Bool
            switch (result) {
            case .failure:
                valid = true

            default:
                valid = false
            }

            self?.validate(valid, cell: self?.timeoutCell)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func validate(_ valid: Bool, cell: UITableViewCell?) {
        if (valid) {
            cell?.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            cell?.textLabel?.textColor = UIColor.red
        }
    }
}
