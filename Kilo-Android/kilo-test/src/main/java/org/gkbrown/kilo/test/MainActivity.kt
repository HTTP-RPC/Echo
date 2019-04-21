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
import android.graphics.Color
import android.os.AsyncTask
import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import android.widget.CheckBox
import com.fasterxml.jackson.databind.ObjectMapper
import kotlinx.android.synthetic.main.activity_main.*
import org.gkbrown.kilo.WebServiceException
import org.gkbrown.kilo.WebServiceProxy
import java.io.InputStreamReader
import java.lang.ref.WeakReference
import java.net.HttpURLConnection
import java.net.URL
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.*

class BackgroundTask<A: Activity, R>(activity: A,
    private val task: () -> R,
    private val resultHandler: (activity: A?, result: Result<R>) -> Unit
) : AsyncTask<Unit, Unit, R?>() {
    private val activityReference = WeakReference<A>(activity)

    private var value: R? = null
    private var exception: Exception? = null

    override fun doInBackground(vararg params: Unit?): R? {
        try {
            value = task()
        } catch (exception: Exception) {
            this.exception = exception
        }

        return value
    }

    override fun onPostExecute(value: R?) {
        resultHandler(activityReference.get(), if (exception == null) {
            Result.success(value!!)
        } else {
            Result.failure(exception!!)
        })
    }
}

fun <A: Activity, R> A.doInBackground(task: () -> R, resultHandler: (activity: A?, result: Result<R>) -> Unit) {
    BackgroundTask(this, task, resultHandler).execute()
}

fun <T> WebServiceProxy.invoke(type: Class<T>): T {
    return invoke { inputStream, _ -> ObjectMapper().readValue(inputStream, type) }
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

    private val date = Date()

    private val localDate = LocalDate.now()
    private val localTime = LocalTime.now()
    private val localDateTime = LocalDateTime.now()

    private val serverURL = URL("http://10.0.2.2:8080/httprpc-test/")

    companion object {
        private const val EOF = -1
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_main)
    }

    override fun onResume() {
        super.onResume()

        // GET
        doInBackground({
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

            webServiceProxy.invoke(Response::class.java)
        }) { activity, result ->
            result.onSuccess { value ->
                validate(value.string == "héllo+gøodbye"
                    && value.strings == listOf("a", "b", "c")
                    && value.number == 123
                    && value.flag == true
                    && value.date == date
                    && value.localDate == localDate.toString()
                    && value.localTime == localTime.toString()
                    && value.localDateTime == localDateTime.toString()
                    && value.attachmentInfo == null, activity?.getCheckBox)
            }.onFailure {
                validate(false, activity?.getCheckBox)
            }
        }

        // GET (Fibonacci)
        doInBackground({
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test/fibonacci"))

            webServiceProxy.arguments = mapOf(
                "count" to 8
            )

            webServiceProxy.invoke(List::class.java)
        }) { activity, result ->
            result.onSuccess { value ->
                validate(value == listOf(0, 1, 1, 2, 3, 5, 8, 13), activity?.getFibonacciCheckBox)
            }.onFailure {
                validate(false, activity?.getFibonacciCheckBox)
            }
        }

        // POST (URL-encoded)
        doInBackground({
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

            webServiceProxy.invoke(Response::class.java)
        }) { activity, result ->
            result.onSuccess { value ->
                validate(value.string == "héllo+gøodbye"
                    && value.strings == listOf("a", "b", "c")
                    && value.number == 123
                    && value.flag == true
                    && value.date == date
                    && value.localDate == localDate.toString()
                    && value.localTime == localTime.toString()
                    && value.localDateTime == localDateTime.toString()
                    && value.attachmentInfo?.isEmpty() ?: true, activity?.postURLEncodedCheckBox)
            }.onFailure {
                validate(false, activity?.postURLEncodedCheckBox)
            }
        }

        // POST (multipart)
        doInBackground({
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

            webServiceProxy.invoke(Response::class.java)
        }) { activity, result ->
            result.onSuccess { value ->
                validate(value.string == "héllo+gøodbye"
                    && value.strings == listOf("a", "b", "c")
                    && value.number == 123
                    && value.flag == true
                    && value.date == date
                    && value.localDate == localDate.toString()
                    && value.localTime == localTime.toString()
                    && value.localDateTime == localDateTime.toString()
                    && value.attachmentInfo == listOf(
                        AttachmentInfo(26, 2412),
                        AttachmentInfo(10392, 1038036)
                    ), activity?.postMultipartCheckBox)
            }.onFailure {
                validate(false, activity?.postMultipartCheckBox)
            }
        }

        // POST (custom)
        doInBackground({
            val webServiceProxy = WebServiceProxy("POST", URL(serverURL, "test"))

            val imageTestURL = javaClass.getResource("/assets/test.jpg") ?: throw RuntimeException()

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

            webServiceProxy.invoke { inputStream, _ -> BitmapFactory.decodeStream(inputStream) }
        }) { activity, result ->
            result.onSuccess { value ->
                validate(value != null, activity?.postCustomCheckBox)
            }.onFailure {
                validate(false, activity?.postCustomCheckBox)
            }
        }

        // PUT
        doInBackground({
            val webServiceProxy = WebServiceProxy("PUT", URL(serverURL, "test"))

            val textTestURL = javaClass.getResource("/assets/test.txt") ?: throw RuntimeException()

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

            webServiceProxy.invoke { inputStream, _ ->
                val inputStreamReader = InputStreamReader(inputStream)

                val textBuilder = StringBuilder()

                var c = inputStreamReader.read()

                while (c != EOF) {
                    textBuilder.append(c.toChar())

                    c = inputStreamReader.read()
                }

                textBuilder.toString()
            }
        }) { activity, result ->
            result.onSuccess { value ->
                validate(value != null, activity?.putCheckBox)
            }.onFailure {
                validate(false, activity?.putCheckBox)
            }
        }

        // DELETE
        doInBackground({
            val webServiceProxy = WebServiceProxy("DELETE", URL(serverURL, "test"))

            webServiceProxy.arguments = mapOf(
                "id" to 101
            )

            webServiceProxy.invoke()
        }) { activity, result ->
            result.onSuccess { value ->
                validate(true, activity?.deleteCheckBox)
            }.onFailure {
                validate(false, activity?.deleteCheckBox)
            }
        }

        // Unauthorized
        doInBackground({
            WebServiceProxy("GET", URL(serverURL, "test/unauthorized")).invoke<Unit>(null)
        }) { activity, result ->
            result.onSuccess {
                validate(false, activity?.unauthorizedCheckBox)
            }.onFailure { exception ->
                validate((exception as? WebServiceException)?.status == HttpURLConnection.HTTP_FORBIDDEN, activity?.unauthorizedCheckBox)
            }
        }

        // Error
        doInBackground({
            WebServiceProxy("GET", URL(serverURL, "test/error")).invoke<Unit>(null)
        }) { activity, result ->
            result.onSuccess {
                validate(false, activity?.errorCheckBox)
            }.onFailure { exception ->
                validate(true, activity?.errorCheckBox)

                print(exception.message ?: "")
            }
        }

        // Timeout
        doInBackground({
            val webServiceProxy = WebServiceProxy("GET", URL(serverURL, "test"))

            webServiceProxy.connectTimeout = 3000
            webServiceProxy.readTimeout = 3000

            webServiceProxy.arguments = mapOf(
                "value" to 123,
                "delay" to 6000
            )

            webServiceProxy.invoke<Any>(null)
        }) { activity, result ->
            result.onSuccess {
                validate(false, activity?.timeoutCheckBox)
            }.onFailure { exception ->
                validate(true, activity?.timeoutCheckBox)
            }
        }
    }

    fun validate(valid: Boolean, checkBox: CheckBox?) {
        checkBox?.isChecked = valid

        if (!valid) {
            checkBox?.setTextColor(Color.RED)
        }
    }
}
