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

import android.app.Activity
import android.graphics.BitmapFactory
import android.os.AsyncTask
import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import com.fasterxml.jackson.databind.ObjectMapper
import kotlinx.android.synthetic.main.activity_main.*
import org.gkbrown.kilo.WebServiceException
import org.gkbrown.kilo.WebServiceProxy
import java.io.InputStreamReader
import java.lang.ref.WeakReference
import java.net.HttpURLConnection
import java.net.SocketTimeoutException
import java.net.URL
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.*

class BackgroundTask<A: Activity, R>(
    val activity: A,
    val task: () -> R,
    val resultHandler: (activity: A?, result: R?, exception: Exception?) -> Unit
) : AsyncTask<Unit, Unit, R?>() {
    private var activityReference = WeakReference<A>(activity)

    private var exception: Exception? = null

    override fun doInBackground(vararg params: Unit?): R? {
        try {
            return task()
        } catch (exception: Exception) {
            this.exception = exception

            return null
        }
    }

    override fun onPostExecute(result: R?) {
        resultHandler(activityReference.get(), result, exception)
    }
}

class MainActivity : AppCompatActivity() {
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

    data class AttachmentInfo(val bytes: Int = 0, val checksum: Long = 0)

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
        BackgroundTask(this, task = {
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

            webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, Map::class.java) }
        }, resultHandler = { activity, result, exception ->
            activity?.getCheckBox?.isChecked = result?.get("string") == "héllo+gøodbye"
                && result?.get("strings") == listOf("a", "b", "c")
                && result?.get("number") == 123
                && result?.get("flag") == true
                && result?.get("date") == date.time
                && result?.get("localDate") == localDate.toString()
                && result?.get("localTime") == localTime.toString()
                && result?.get("localDateTime") == localDateTime.toString()
        }).execute()

        // GET (Fibonacci)
        BackgroundTask(this, task = {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test/fibonacci"))

            webServiceProxy.arguments = mapOf(
                "count" to 8
            )

            webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, List::class.java) }
        }, resultHandler = { activity, result, exception ->
            activity?.getFibonacciCheckBox?.isChecked = (result == listOf(0, 1, 1, 2, 3, 5, 8, 13))
        }).execute()

        // POST (URL-encoded)
        BackgroundTask(this, task = {
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

            webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, Response::class.java) }
        }, resultHandler = { activity, result, exception ->
            activity?.postURLEncodedCheckBox?.isChecked = result?.string == "héllo+gøodbye"
                && result?.strings == listOf("a", "b", "c")
                && result?.number == 123
                && result?.flag == true
                && result?.date == date
                && result?.localDate == localDate.toString()
                && result?.localTime == localTime.toString()
                && result?.localDateTime == localDateTime.toString()
                && result?.attachmentInfo?.isEmpty() ?: true
        }).execute()

        // POST (multipart)
        BackgroundTask(this, task = {
            val webServiceProxy = WebServiceProxy("POST", URL(serverURL, "test"))

            webServiceProxy.encoding = WebServiceProxy.Encoding.MULTIPART_FORM_DATA

            val textTestURL = javaClass.getResource("/assets/test.txt")
            val imageTestURL = javaClass.getResource("/assets/test.jpg")

            webServiceProxy.arguments = mapOf(
                "string" to "héllo+gøodbye",
                "strings" to listOf("a", "b", "c"),
                "number" to 123,
                "flag" to true,
                "date" to date,
                "localDate" to localDate,
                "localTime" to localTime,
                "localDateTime" to localDateTime,
                "attachments" to listOf(textTestURL, imageTestURL)
            )

            webServiceProxy.invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, Response::class.java) }
        }, resultHandler = { activity, result, exception ->
            activity?.postMultipartCheckBox?.isChecked = result?.string == "héllo+gøodbye"
                && result?.strings == listOf("a", "b", "c")
                && result?.number == 123
                && result?.flag == true
                && result?.date == date
                && result?.localDate == localDate.toString()
                && result?.localTime == localTime.toString()
                && result?.localDateTime == localDateTime.toString()
                && result?.attachmentInfo == listOf(
                AttachmentInfo(26, 2412),
                AttachmentInfo(10392, 1038036)
            )
        }).execute()

        // POST (custom)
        BackgroundTask(this, task = {
            val webServiceProxy = WebServiceProxy("POST", URL(serverURL, "test"))

            val imageTestURL = javaClass.getResource("/assets/test.jpg")

            webServiceProxy.setRequestHandler { outputStream ->
                imageTestURL.openStream().use { inputStream ->
                    var b = inputStream.read()

                    while (b != EOF) {
                        outputStream.write(b)

                        b = inputStream.read()
                    }
                }
            }

            webServiceProxy.arguments = mapOf(
                "name" to imageTestURL.file
            )

            webServiceProxy.invoke { inputStream, contentType -> BitmapFactory.decodeStream(inputStream) }
        }, resultHandler = { activity, result, exception ->
            activity?.postCustomCheckBox?.isChecked = (result != null)
        }).execute()

        // PUT
        BackgroundTask(this, task = {
            val webServiceProxy = WebServiceProxy("PUT", URL(serverURL, "test"))

            val textTestURL = javaClass.getResource("/assets/test.txt")

            webServiceProxy.setRequestHandler { outputStream ->
                textTestURL.openStream().use { inputStream ->
                    var b = inputStream.read()

                    while (b != EOF) {
                        outputStream.write(b)

                        b = inputStream.read()
                    }
                }
            }

            webServiceProxy.arguments = mapOf(
                "id" to 101
            )

            webServiceProxy.invoke { inputStream, contentType ->
                val inputStreamReader = InputStreamReader(inputStream)

                val textBuilder = StringBuilder()

                var c = inputStreamReader.read()

                while (c != EOF) {
                    textBuilder.append(c.toChar())

                    c = inputStreamReader.read()
                }

                textBuilder.toString()
            }
        }, resultHandler = { activity, result, exception ->
            activity?.putCheckBox?.isChecked = (result != null)
        }).execute()

        // DELETE
        BackgroundTask(this, task = {
            val webServiceProxy = WebServiceProxy("DELETE", URL(serverURL, "test"))

            webServiceProxy.arguments = mapOf(
                "id" to 101
            )

            webServiceProxy.invoke<Unit>(null)
        }, resultHandler = { activity, result, exception ->
            activity?.deleteCheckBox?.isChecked = (exception == null)
        }).execute()

        // Unauthorized
        BackgroundTask(this, task = {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test/unauthorized"))

            try {
                webServiceProxy.invoke<Unit>(null)

                HttpURLConnection.HTTP_OK
            } catch (exception: WebServiceException) {
                exception.status
            }
        }, resultHandler = { activity, result, exception ->
            activity?.unauthorizedCheckBox?.isChecked = (result == HttpURLConnection.HTTP_FORBIDDEN)
        }).execute()

        // Error
        BackgroundTask(this, task = {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test/error"))

            try {
                webServiceProxy.invoke<Unit>(null)

                false
            } catch (exception: WebServiceException) {
                print(exception.message)

                true
            }
        }, resultHandler = { activity, result, exception ->
            activity?.errorCheckBox?.isChecked = result ?: false
        }).execute()

        // Timeout
        BackgroundTask(this, task = {
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test"))

            webServiceProxy.connectTimeout = 3000
            webServiceProxy.readTimeout = 3000

            webServiceProxy.arguments = mapOf(
                "value" to 123,
                "delay" to 6000
            )

            try {
                webServiceProxy.invoke<Any>(null)

                false
            } catch (exception: SocketTimeoutException) {
                true
            }
        }, resultHandler = { activity, result, exception ->
            activity?.timeoutCheckBox?.isChecked = result?: false
        }).execute()
    }
}
