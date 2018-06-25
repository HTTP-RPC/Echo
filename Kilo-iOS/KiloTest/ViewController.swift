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

class ViewController: LMTableViewController {
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

        // Create web service proxy
        let session = URLSession(configuration: sessionConfiguration)

        let webServiceProxy = WebServiceProxy(session: session, serverURL: URL(string: "http://localhost")!)

        // TODO GET (w/date argument)
        webServiceProxy.invoke(.get, path: "/httprpc-server/test") { (result: [String: Any]?, error: Error?) in
        }

        // TODO URL-encoded post (w/date argument)
        webServiceProxy.invoke(.post, path: "/httprpc-server/test") { (_: Void?, error: Error?) in
        }

        // TODO Multi-part post (w/date argument)

        // TODO Custom post

        // TODO PUT (w/body)

        // TODO PATCH (w/body)

        // TODO DELETE

        // TODO Error

        // TODO Timeout

        // TODO Cancel
        let task: URLSessionTask? = nil

        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            task?.cancel()
        }
    }

    override func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func validate(_ condition: Bool, error: Error?, cell: UITableViewCell) {
        if (condition) {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.textLabel?.textColor = UIColor.red
        }
    }
}
