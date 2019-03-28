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

package org.gkbrown.kilo;

import org.httprpc.io.JSONDecoder;
import org.junit.Assert;
import org.junit.Test;

import java.awt.image.BufferedImage;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.AbstractMap;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.imageio.ImageIO;

public class WebServiceProxyTest {
    private static Date date = new Date();

    private static LocalDate localDate = LocalDate.now();
    private static LocalTime localTime = LocalTime.now();
    private static LocalDateTime localDateTime = LocalDateTime.now();

    private static final int EOF = -1;

    @Test
    public void testGet() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL("http://localhost:8080/httprpc-test/test"));

        webServiceProxy.setArguments(mapOf(
            entry("string", "héllo+gøodbye"),
            entry("strings", listOf("a", "b", "c")),
            entry("number", 123),
            entry("flag", true),
            entry("date", date),
            entry("localDate", localDate),
            entry("localTime", localTime),
            entry("localDateTime", localDateTime)
        ));

        Map<String, ?> result = webServiceProxy.invoke((inputStream, contentType) -> new JSONDecoder().read(inputStream));

        Assert.assertTrue("GET", result.get("string").equals("héllo+gøodbye")
            && result.get("strings").equals(listOf("a", "b", "c"))
            && result.get("number").equals(123L)
            && result.get("flag").equals(true)
            && result.get("date").equals(date.getTime())
            && result.get("localDate").equals(localDate.toString())
            && result.get("localTime").equals(localTime.toString())
            && result.get("localDateTime").equals(localDateTime.toString()));
    }

    @Test
    public void testURLEncodedPost() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("POST", new URL("http://localhost:8080/httprpc-test/test"));

        webServiceProxy.setArguments(mapOf(
            entry("string", "héllo+gøodbye"),
            entry("strings", listOf("a", "b", "c")),
            entry("number", 123L),
            entry("flag", true),
            entry("date", date),
            entry("localDate", localDate),
            entry("localTime", localTime),
            entry("localDateTime", localDateTime)
        ));

        Map<String, ?> result = webServiceProxy.invoke((inputStream, contentType) -> new JSONDecoder().read(inputStream));

        Assert.assertTrue("POST (URL-encoded)", result.get("string").equals("héllo+gøodbye")
            && result.get("strings").equals(listOf("a", "b", "c"))
            && result.get("number").equals(123L)
            && result.get("flag").equals(true)
            && result.get("date").equals(date.getTime())
            && result.get("localDate").equals(localDate.toString())
            && result.get("localTime").equals(localTime.toString())
            && result.get("localDateTime").equals(localDateTime.toString())
            && result.get("attachmentInfo").equals(listOf()));
    }

    @Test
    public void testMultipartPost() throws Exception {
        URL textTestURL = WebServiceProxyTest.class.getResource("test.txt");
        URL imageTestURL = WebServiceProxyTest.class.getResource("test.jpg");

        WebServiceProxy webServiceProxy = new WebServiceProxy("POST", new URL("http://localhost:8080/httprpc-test/test"));

        webServiceProxy.setEncoding(WebServiceProxy.Encoding.MULTIPART_FORM_DATA);

        webServiceProxy.setArguments(mapOf(
            entry("string", "héllo+gøodbye"),
            entry("strings", listOf("a", "b", "c")),
            entry("number", 123L),
            entry("flag", true),
            entry("date", date),
            entry("localDate", localDate),
            entry("localTime", localTime),
            entry("localDateTime", localDateTime),
            entry("attachments", listOf(textTestURL, imageTestURL))
        ));

        Map<String, ?> result = webServiceProxy.invoke((inputStream, contentType) -> new JSONDecoder().read(inputStream));

        Assert.assertTrue("POST (multipart)", result.get("string").equals("héllo+gøodbye")
            && result.get("strings").equals(listOf("a", "b", "c"))
            && result.get("number").equals(123L)
            && result.get("flag").equals(true)
            && result.get("date").equals(date.getTime())
            && result.get("localDate").equals(localDate.toString())
            && result.get("localTime").equals(localTime.toString())
            && result.get("localDateTime").equals(localDateTime.toString())
            && result.get("attachmentInfo").equals(listOf(
                mapOf(
                    entry("bytes", 26L),
                    entry("checksum", 2412L)
                ),
                mapOf(
                    entry("bytes", 10392L),
                    entry("checksum", 1038036L)
                )
            ))
        );
    }

    @Test
    public void testCustomPost() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("POST", new URL("http://localhost:8080/httprpc-test/test"));

        URL imageTestURL = WebServiceProxyTest.class.getResource("test.jpg");

        webServiceProxy.setRequestHandler((outputStream) -> {
            try (InputStream inputStream = imageTestURL.openStream()) {
                int b;
                while ((b = inputStream.read()) != -1) {
                    outputStream.write(b);
                }
            }
        });

        webServiceProxy.setArguments(mapOf(
            entry("name", imageTestURL.getFile())
        ));

        BufferedImage image = webServiceProxy.invoke((inputStream, contentType) -> {
            return ImageIO.read(inputStream);
        });

        Assert.assertTrue("POST (custom)", image != null);
    }

    @Test
    public void testPut() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("PUT", new URL("http://localhost:8080/httprpc-test/test"));

        URL textTestURL = WebServiceProxyTest.class.getResource("test.txt");

        webServiceProxy.setRequestHandler((outputStream) -> {
            try (InputStream inputStream = textTestURL.openStream()) {
                int b;
                while ((b = inputStream.read()) != EOF) {
                    outputStream.write(b);
                }
            }
        });

        webServiceProxy.setArguments(mapOf(
            entry("id", 101)
        ));

        String text = webServiceProxy.invoke((inputStream, contentType) -> {
            InputStreamReader inputStreamReader = new InputStreamReader(inputStream);

            StringBuilder textBuilder = new StringBuilder();

            int c;
            while ((c = inputStreamReader.read()) != EOF) {
                textBuilder.append((char)c);
            }

            return textBuilder.toString();
        });

        Assert.assertTrue("PUT", text != null);
    }

    @Test
    public void testDelete() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("DELETE", new URL("http://localhost:8080/httprpc-test/test"));

        webServiceProxy.setArguments(mapOf(
            entry("id", 101)
        ));

        webServiceProxy.invoke(null);

        Assert.assertTrue("DELETE", true);
    }

    @Test
    public void testUnauthorized() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL("http://localhost:8080/httprpc-test/test/unauthorized"));

        int status;
        try {
            webServiceProxy.invoke(null);

            status = HttpURLConnection.HTTP_OK;
        } catch (WebServiceException exception) {
            status = exception.getStatus();
        }

        Assert.assertTrue("Unauthorized", status == HttpURLConnection.HTTP_FORBIDDEN);
    }

    @Test
    public void testError() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL("http://localhost:8080/httprpc-test/test/error"));

        boolean error;
        try {
            webServiceProxy.invoke(null);

            error = false;
        } catch (WebServiceException exception) {
            error = true;
        }

        Assert.assertTrue("Error", error);
    }

    @Test
    public void testTimeout() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL("http://localhost:8080/httprpc-test/test"));

        webServiceProxy.setConnectTimeout(3000);
        webServiceProxy.setReadTimeout(3000);

        webServiceProxy.setArguments(mapOf(
            entry("value", 123),
            entry("delay", 6000)
        ));

        boolean timeout;
        try {
            webServiceProxy.invoke(null);

            timeout = false;
        } catch (SocketTimeoutException exception) {
            timeout = true;
        }

        Assert.assertTrue("Timeout", timeout);
    }

    @SafeVarargs
    private static <E> List<E> listOf(E... elements) {
        return Collections.unmodifiableList(Arrays.asList(elements));
    }

    @SafeVarargs
    private static <K, V> Map<K, V> mapOf(Map.Entry<K, V>... entries) {
        HashMap<K, V> map = new HashMap<>();

        for (Map.Entry<K, V> entry : entries) {
            map.put(entry.getKey(), entry.getValue());
        }

        return Collections.unmodifiableMap(map);
    }

    private static <K, V> Map.Entry<K, V> entry(K key, V value) {
        return new AbstractMap.SimpleImmutableEntry<>(key, value);
    }
}