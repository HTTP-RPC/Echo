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

import Foundation

/**
 * Swift refinements to web service proxy.
 */
extension WSWebServiceProxy {
    @discardableResult
    open func invoke<T, E: Error>(_ method: WSMethod, path: String,
        arguments: [String: Any]? = nil, body: Data? = nil,
        resultHandler: @escaping (T?, E?) -> Void) -> URLSessionTask? {
        return __invoke(method, path: path, arguments: arguments, body: body) { result, error in
            resultHandler(result as! T?, error as! E?)
        }
    }

    @discardableResult
    open func invoke<T, E: Error>(_ method: WSMethod, path: String,
        arguments: [String: Any]? = nil, body: Data? = nil,
        responseHandler: @escaping (Data, String) throws -> T?,
        resultHandler: @escaping (T?, E?) -> Void) -> URLSessionTask? {
        return __invoke(method, path: path, arguments: arguments, body: body, responseHandler: { data, contentType, errorPointer in
            let result: Any?
            do {
                result = try responseHandler(data, contentType)
            } catch {
                if (errorPointer != nil) {
                    errorPointer!.pointee = error as NSError
                }

                result = nil
            }

            return result
        }) { result, error in
            resultHandler(result as! T?, error as! E?)
        }
    }
}
