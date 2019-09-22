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

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
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

public class WebServiceProxyTest {
    private Date date = new Date();

    private LocalDate localDate = LocalDate.now();
    private LocalTime localTime = LocalTime.now();
    private LocalDateTime localDateTime = LocalDateTime.now();

    private URL serverURL;

    private static final int EOF = -1;

    public static class Response {
        private String string = null;
        private List<String> strings = null;
        private int number = 0;
        private boolean flag = false;
        private Date date = null;
        private String localDate = null;
        private String localTime = null;
        private String localDateTime = null;
        private List<AttachmentInfo> attachmentInfo = null;

        public String getString() {
            return string;
        }

        public List<String> getStrings() {
            return strings;
        }

        public int getNumber() {
            return number;
        }

        public boolean getFlag() {
            return flag;
        }

        public Date getDate() {
            return date;
        }

        public String getLocalDate() {
            return localDate;
        }

        public String getLocalTime() {
            return localTime;
        }

        public String getLocalDateTime() {
            return localDateTime;
        }

        public List<AttachmentInfo> getAttachmentInfo() {
            return attachmentInfo;
        }
    }

    public static class AttachmentInfo {
        private int bytes = 0;
        private int checksum = 0;

        public int getBytes() {
            return bytes;
        }

        public int getChecksum() {
            return checksum;
        }
    }

    public WebServiceProxyTest() throws IOException {
        serverURL = new URL("http://localhost:8080/httprpc-test-1.0/");
    }

    @Test
    public void testGet() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test"));

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

        Response result = webServiceProxy.invoke((inputStream, contentType, headers) -> new ObjectMapper().readValue(inputStream, Response.class));

        Assertions.assertTrue(result.getString().equals("héllo+gøodbye")
            && result.getStrings().equals(listOf("a", "b", "c"))
            && result.getNumber() == 123
            && result.getFlag() == true
            && result.getDate().equals(date)
            && result.getLocalDate().equals(localDate.toString())
            && result.getLocalTime().equals(localTime.toString())
            && result.getLocalDateTime().equals(localDateTime.toString())
            && result.getAttachmentInfo() == null);
    }

    @Test
    public void testGetFibonacci() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test/fibonacci"));

        webServiceProxy.setArguments(mapOf(
            entry("count", 8)
        ));

        List<Integer> result = webServiceProxy.invoke((inputStream, contentType, headers) -> new ObjectMapper().readValue(inputStream,
            new TypeReference<List<Integer>>(){}));

        Assertions.assertEquals(result, listOf(0, 1, 1, 2, 3, 5, 8, 13));
    }

    @Test
    public void testURLEncodedPost() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("POST", new URL(serverURL, "test"));

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

        Response result = webServiceProxy.invoke((inputStream, contentType, headers) -> new ObjectMapper().readValue(inputStream, Response.class));

        Assertions.assertTrue(result.getString().equals("héllo+gøodbye")
            && result.getStrings().equals(listOf("a", "b", "c"))
            && result.getNumber() == 123
            && result.getFlag() == true
            && result.getDate().equals(date)
            && result.getLocalDate().equals(localDate.toString())
            && result.getLocalTime().equals(localTime.toString())
            && result.getLocalDateTime().equals(localDateTime.toString())
            && result.getAttachmentInfo().size() == 0);
    }

    @Test
    public void testMultipartPost() throws IOException {
        URL textTestURL = WebServiceProxyTest.class.getResource("test.txt");
        URL imageTestURL = WebServiceProxyTest.class.getResource("test.jpg");

        WebServiceProxy webServiceProxy = new WebServiceProxy("POST", new URL(serverURL, "test"));

        webServiceProxy.setEncoding(WebServiceProxy.Encoding.MULTIPART_FORM_DATA);

        webServiceProxy.setArguments(mapOf(
            entry("string", "héllo+gøodbye"),
            entry("strings", listOf("a", "b", "c")),
            entry("number", 123),
            entry("flag", true),
            entry("date", date),
            entry("localDate", localDate),
            entry("localTime", localTime),
            entry("localDateTime", localDateTime),
            entry("attachments", listOf(textTestURL, imageTestURL))
        ));

        Response result = webServiceProxy.invoke((inputStream, contentType, headers) -> new ObjectMapper().readValue(inputStream, Response.class));

        Assertions.assertTrue(result.getString().equals("héllo+gøodbye")
            && result.getStrings().equals(listOf("a", "b", "c"))
            && result.getNumber() == 123
            && result.getFlag() == true
            && result.getDate().equals(date)
            && result.getLocalDate().equals(localDate.toString())
            && result.getLocalTime().equals(localTime.toString())
            && result.getLocalDateTime().equals(localDateTime.toString())
            && result.getAttachmentInfo().get(0).getBytes() == 26
            && result.getAttachmentInfo().get(0).getChecksum() == 2412
            && result.getAttachmentInfo().get(1).getBytes() == 10392
            && result.getAttachmentInfo().get(1).getChecksum() == 1038036);
    }

    @Test
    public void testCustomPost() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("POST", new URL(serverURL, "test"));

        URL imageTestURL = WebServiceProxyTest.class.getResource("test.jpg");

        webServiceProxy.setRequestHandler((outputStream) -> {
            try (InputStream inputStream = imageTestURL.openStream()) {
                int b;
                while ((b = inputStream.read()) != EOF) {
                    outputStream.write(b);
                }
            }
        });

        webServiceProxy.setArguments(mapOf(
            entry("name", imageTestURL.getFile())
        ));

        BufferedImage image = webServiceProxy.invoke((inputStream, contentType, headers) -> ImageIO.read(inputStream));

        Assertions.assertNotNull(image);
    }

    @Test
    public void testPut() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("PUT", new URL(serverURL, "test"));

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

        String text = webServiceProxy.invoke((inputStream, contentType, headers) -> {
            InputStreamReader inputStreamReader = new InputStreamReader(inputStream);

            StringBuilder textBuilder = new StringBuilder();

            int c;
            while ((c = inputStreamReader.read()) != EOF) {
                textBuilder.append((char)c);
            }

            return textBuilder.toString();
        });

        Assertions.assertNotNull(text);
    }

    @Test
    public void testDelete() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("DELETE", new URL(serverURL, "test"));

        webServiceProxy.setArguments(mapOf(
            entry("id", 101)
        ));

        webServiceProxy.invoke();

        Assertions.assertTrue(true);
    }

    @Test
    public void testUnauthorized() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test/unauthorized"));

        int statusCode;
        try {
            webServiceProxy.invoke();

            statusCode = HttpURLConnection.HTTP_OK;
        } catch (WebServiceException exception) {
            statusCode = exception.getStatusCode();
        }

        Assertions.assertEquals(HttpURLConnection.HTTP_FORBIDDEN, statusCode);
    }

    @Test
    public void testError() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test/error"));

        boolean error;
        try {
            webServiceProxy.invoke();

            error = false;
        } catch (WebServiceException exception) {
            error = true;
        }

        Assertions.assertTrue(error);
    }

    @Test
    public void testTimeout() throws IOException {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test"));

        webServiceProxy.setConnectTimeout(500);
        webServiceProxy.setReadTimeout(4000);

        webServiceProxy.setArguments(mapOf(
            entry("value", 123),
            entry("delay", 6000)
        ));

        boolean timeout;
        try {
            webServiceProxy.invoke((inputStream, contentType, headers) -> new ObjectMapper().readValue(inputStream, Integer.class));

            timeout = false;
        } catch (IOException exception) {
            timeout = (exception instanceof SocketTimeoutException);
        }

        Assertions.assertTrue(timeout);
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