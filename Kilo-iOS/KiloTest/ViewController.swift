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
import MarkupKit
import Kilo

class ViewController: LMTableViewController, URLSessionDataDelegate {
    @IBOutlet var getCell: UITableViewCell!
    @IBOutlet var postURLEncodedCell: UITableViewCell!
    @IBOutlet var postMultipartCell: UITableViewCell!
    @IBOutlet var postCustomCell: UITableViewCell!
    @IBOutlet var putCell: UITableViewCell!
    @IBOutlet var patchCell: UITableViewCell!
    @IBOutlet var deleteCell: UITableViewCell!
    @IBOutlet var timeoutCell: UITableViewCell!
    @IBOutlet var cancelCell: UITableViewCell!
    @IBOutlet var errorCell: UITableViewCell!
    @IBOutlet var imageCell: UITableViewCell!
    @IBOutlet var textCell: UITableViewCell!
    @IBOutlet var customResponseCell: UITableViewCell!

    override func loadView() {
        view = LMViewBuilder.view(withName: "ViewController", owner: self, root: nil)

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Kilo Test"

        // Configure session
        let sessionConfiguration = URLSessionConfiguration.default

        sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        sessionConfiguration.timeoutIntervalForResource = 3

        // TODO Set credentials

        // Create service proxy
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)

        let serviceProxy = WSWebServiceProxy(session: session, serverURL: URL(string: "https://localhost:8443")!)

        // GET
        // TODO Date argument
        serviceProxy.invoke(.get, path: "/httprpc-server/test", arguments: [
            "string": "héllo+gøodbye",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            ]) { (result: NSDictionary?, error: NSError?) in
            if let dictionary = result {
                self.validate(dictionary.value(forKeyPath: "string") as? String == "héllo+gøodbye"
                    && dictionary.value(forKeyPath: "strings") as? [String] ?? [] == ["a", "b", "c"]
                    && dictionary.value(forKeyPath: "number") as? Int == 123
                    && dictionary.value(forKeyPath: "flag") as? Bool == true,
                    error: error, cell: self.getCell)
            }
        }

        // POST
        let textTestURL = Bundle.main.url(forResource: "test", withExtension: "txt")!
        let imageTestURL = Bundle.main.url(forResource: "test", withExtension: "jpg")!

        // TODO Date argument
        serviceProxy.invoke(.post, path: "/httprpc-server/test", arguments: [
            "string": "héllo",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true
            ]) { (result: NSDictionary?, error: NSError?) in
            self.validate(result == [
                "string": "héllo",
                "strings": ["a", "b", "c"],
                "number": 123,
                "flag": true,
                "attachmentInfo": [
                ]
            ], error: error, cell: self.postURLEncodedCell)
        }

        serviceProxy.encoding = .multipartFormData

        // TODO Date argument
        serviceProxy.invoke(.post, path: "/httprpc-server/test", arguments: [
            "string": "héllo",
            "strings": ["a", "b", "c"],
            "number": 123,
            "flag": true,
            "attachments": [textTestURL, imageTestURL]
            ]) { (result: NSDictionary?, error: NSError?) in
            self.validate(result == [
                "string": "héllo",
                "strings": ["a", "b", "c"],
                "number": 123,
                "flag": true,
                "attachmentInfo": [
                    [
                        "bytes": 26,
                        "checksum": 2412
                    ],
                    [
                        "bytes": 10392,
                        "checksum": 1038036
                    ]
                ]
            ], error: error, cell: self.postMultipartCell)
        }

        // TODO POST custom

        // TODO PUT (w/body)

        // TODO PATCH (w/body)

        // DELETE
        serviceProxy.invoke(.delete, path: "/httprpc-server/test", arguments: ["id": 101]) { (result: Bool?, error: NSError?) in
            self.validate(result == true, error: error, cell: self.deleteCell)
        }

        // Error
        serviceProxy.invoke(.get, path: "/httprpc-server/test/error") { (_: Any?, error: NSError?) in
            self.errorCell.detailTextLabel?.text = error?.localizedDescription

            self.validate(error != nil && error!.domain == WSWebServiceErrorDomain && error!.code == 500, error: error, cell: self.errorCell)
        }

        // Timeout
        serviceProxy.invoke(.get, path: "/httprpc-server/test", arguments: ["value": 123, "delay": 6000]) { (_: Any?, error: NSError?) in
            self.validate(error != nil, error: error, cell: self.timeoutCell)
        }

        // Cancel
        let task = serviceProxy.invoke(.get, path: "/httprpc-server/test", arguments: ["value": 123, "delay": 6000]) { (_: Any?, error: NSError?) in
            self.validate(error != nil, error: error, cell: self.cancelCell)
        }

        Timer.scheduledTimer(timeInterval: 1, target: BlockOperation(block: {
            task!.cancel()
        }), selector: #selector(Operation.main), userInfo: nil, repeats: false)

        // Image
        serviceProxy.invoke(.get, path: "/httprpc-server/test.jpg") { (result: UIImage?, error: NSError?) in
            self.validate(result != nil, error: error, cell: self.imageCell)

            self.imageCell.imageView?.image = result
        }

        // Image
        serviceProxy.invoke(.get, path: "/httprpc-server/test.txt") { (result: String?, error: NSError?) in
            self.validate(result != nil, error: error, cell: self.textCell)

            self.textCell.textLabel?.text = result
        }

        // Custom response
        serviceProxy.invoke(.get, path: "/httprpc-server/test.txt", responseHandler: { data, contentType in
            return String(data: data, encoding: .utf8)?.lowercased()
        }) { (result: String?, error: NSError?) in
            self.validate(result != nil, error: error, cell: self.customResponseCell)

            self.customResponseCell.textLabel?.text = result
        }
    }

    override func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func validate(_ condition: Bool, error: Error?, cell: UITableViewCell) {
        if (condition) {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.textLabel!.textColor = UIColor.red

            if (error != nil) {
                print(error!.localizedDescription)
            }
        }
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Allow self-signed certificates for testing purposes
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
}
