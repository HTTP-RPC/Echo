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
import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.widget.CheckBox
import java.net.URL
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.Date
import org.gkbrown.kilo.WebServiceProxy
import com.fasterxml.jackson.databind.ObjectMapper
import kotlinx.android.synthetic.main.activity_main.*

class MainActivity : AppCompatActivity() {
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
                && result.get("date") == date.getTime()
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
    }
}

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