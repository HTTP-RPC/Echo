/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.gkbrown.kilo.test

import android.os.AsyncTask
import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import android.widget.CheckBox
import java.net.HttpURLConnection
import java.net.SocketTimeoutException
import java.net.URL
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.*
import org.gkbrown.kilo.WebServiceException
import org.gkbrown.kilo.WebServiceProxy
import com.fasterxml.jackson.databind.ObjectMapper
import kotlinx.android.synthetic.main.activity_main.*

class MainActivity : AppCompatActivity() {
    class TestTask(val checkBox: CheckBox, val test: () -> Boolean) : AsyncTask<Unit, Unit, Boolean>() {
        override fun doInBackground(vararg params: Unit?): Boolean {
            try {
                return test()
            } catch (exception: Exception) {
                return false
            }
        }

        override fun onPostExecute(result: Boolean?) {
            checkBox.setChecked(result ?: false)
        }
    }

    class Response {
        val string: String? = null
        val strings: List<String>? = null
        val number = 0
        val flag = false
        val date: Date? = null
        val localDate: String? = null
        val localTime: String? = null
        val localDateTime: String? = null
        val attachmentInfo: List<AttachmentInfo>? = null
    }

    class AttachmentInfo {
        val bytes = 0
        val checksum = 0
    }

    val date = Date()

    val localDate = LocalDate.now()
    val localTime = LocalTime.now()
    val localDateTime = LocalDateTime.now()

    val serverURL = URL("http://10.0.2.2:8080/httprpc-test/")

    val EOF = -1

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_main)
    }

    override fun onResume() {
        super.onResume()

        // GET
        TestTask(getCheckBox) {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test"))

            webServiceProxy.arguments = mapOf(
                "string" to "héllo+gøodbye",
                "strings" to listOf("a", "b", "c"),
                "number" to 123,
                "flag" to true,
                "date" to date,
                "localDate" to localDate,
                "localTime" to localTime,
                "localDateTime" to localDateTime
            )

            val result = webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, Map::class.java) }

            result.get("string") == "héllo+gøodbye"
                && result.get("strings") == listOf("a", "b", "c")
                && result.get("number") == 123
                && result.get("flag") == true
                && result.get("date") == date.time
                && result.get("localDate") == localDate.toString()
                && result.get("localTime") == localTime.toString()
                && result.get("localDateTime") == localDateTime.toString()
        }.execute()

        // GET (Fibonacci)
        TestTask(getFibonacciCheckBox) {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test/fibonacci"))

            webServiceProxy.arguments = mapOf(
                "count" to 8
            )

            val result = webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, List::class.java) }

            result == listOf(0, 1, 1, 2, 3, 5, 8, 13)
        }.execute()

        // POST (URL-encoded)
        TestTask(postURLEncodedCheckBox) {
            val webServiceProxy = WebServiceProxy("POST", URL(serverURL, "test"))

            webServiceProxy.arguments = mapOf(
                "string" to "héllo+gøodbye",
                "strings" to listOf("a", "b", "c"),
                "number" to 123,
                "flag" to true,
                "date" to date,
                "localDate" to localDate,
                "localTime" to localTime,
                "localDateTime" to localDateTime
            )

            val result = webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, Response::class.java) }

            result.string == "héllo+gøodbye"
                && result.strings == listOf("a", "b", "c")
                && result.number == 123
                && result.flag == true
                && result.date == date
                && result.localDate == localDate.toString()
                && result.localTime == localTime.toString()
                && result.localDateTime == localDateTime.toString()
                && result.attachmentInfo?.isEmpty() ?: true
        }.execute()

        // POST (multipart)
        TestTask(postMultipartCheckBox) {
            val webServiceProxy = WebServiceProxy("POST", URL(serverURL, "test"))

            webServiceProxy.encoding = WebServiceProxy.Encoding.MULTIPART_FORM_DATA

            // TODO Attachments
            webServiceProxy.arguments = mapOf(
                "string" to "héllo+gøodbye",
                "strings" to listOf("a", "b", "c"),
                "number" to 123,
                "flag" to true,
                "date" to date,
                "localDate" to localDate,
                "localTime" to localTime,
                "localDateTime" to localDateTime
            )

            val result = webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, Response::class.java) }

            result.string == "héllo+gøodbye"
                && result.strings == listOf("a", "b", "c")
                && result.number == 123
                && result.flag == true
                && result.date == date
                && result.localDate == localDate.toString()
                && result.localTime == localTime.toString()
                && result.localDateTime == localDateTime.toString()
                && result.attachmentInfo?.isEmpty() ?: true
        }.execute()

        // POST (custom)
        TestTask(postCustomCheckBox) {
            // TODO
            false
        }.execute()

        // PUT
        TestTask(putCheckBox) {
            // TODO
            false
        }.execute()

        // DELETE
        TestTask(deleteCheckBox) {
            val webServiceProxy = WebServiceProxy("DELETE", URL(serverURL, "test"))

            webServiceProxy.arguments = mapOf(
                "id" to 101
            )

            webServiceProxy.invoke<Unit>(null)

            true
        }.execute()

        // Unauthorized
        TestTask(unauthorizedCheckBox) {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test/unauthorized"))

            val status = try {
                webServiceProxy.invoke<Unit>(null)

                HttpURLConnection.HTTP_OK
            } catch (exception: WebServiceException) {
                exception.status
            }

            status == HttpURLConnection.HTTP_FORBIDDEN
        }.execute()

        // Error
        TestTask(errorCheckBox) {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test/error"))

            val error = try {
                webServiceProxy.invoke<Unit>(null)

                false
            } catch (exception: WebServiceException) {
                print(exception.message)

                true
            }

            error
        }.execute()

        // Timeout
        TestTask(timeoutCheckBox) {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test"))

            webServiceProxy.connectTimeout = 3000
            webServiceProxy.readTimeout = 3000

            webServiceProxy.arguments = mapOf(
                "value" to 123,
                "delay" to 6000
            )

            val timeout = try {
                webServiceProxy.invoke<Any>(null)

                false
            } catch (exception: SocketTimeoutException) {
                true
            }

            timeout
        }.execute()
    }
}
