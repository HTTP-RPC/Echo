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

import com.fasterxml.jackson.databind.ObjectMapper;

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
    private Date date = new Date();

    private LocalDate localDate = LocalDate.now();
    private LocalTime localTime = LocalTime.now();
    private LocalDateTime localDateTime = LocalDateTime.now();

    private URL serverURL;

    private static final int EOF = -1;

    public static class Response {
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

    public WebServiceProxyTest() throws Exception {
        serverURL = new URL("http://localhost:8080/httprpc-test/");
    }

    @Test
    public void testGreeting() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "greeting"));

        String result = webServiceProxy.invoke((inputStream, contentType) -> new ObjectMapper().readValue(inputStream, String.class));

        Assert.assertEquals(result, "Hello, World!");
    }

    @Test
    public void testSum() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "math/sum"));

        webServiceProxy.setArguments(mapOf(entry("a", 2), entry("b", 4)));

        Number result = webServiceProxy.invoke((inputStream, contentType) -> new ObjectMapper().readValue(inputStream, Number.class));

        Assert.assertEquals(6, result.intValue());
    }

    @Test
    public void testSumValues() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "math/sum"));

        webServiceProxy.setArguments(mapOf(entry("values", listOf(1, 2, 3))));

        Number result = webServiceProxy.invoke((inputStream, contentType) -> new ObjectMapper().readValue(inputStream, Number.class));

        Assert.assertEquals(6, result.intValue());
    }

    @Test
    public void testGet() throws Exception {
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

        Map<String, ?> result = webServiceProxy.invoke((inputStream, contentType) -> new ObjectMapper().readValue(inputStream, Map.class));

        Assert.assertTrue("GET", result.get("string").equals("héllo+gøodbye")
            && result.get("strings").equals(listOf("a", "b", "c"))
            && result.get("number").equals(123)
            && result.get("flag").equals(true)
            && result.get("date").equals(date.getTime())
            && result.get("localDate").equals(localDate.toString())
            && result.get("localTime").equals(localTime.toString())
            && result.get("localDateTime").equals(localDateTime.toString()));
    }

    @Test
    public void testURLEncodedPost() throws Exception {
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

        Response result = webServiceProxy.invoke((inputStream, contentType) -> new ObjectMapper().readValue(inputStream, Response.class));

        Assert.assertTrue("POST (multipart)", result.getString().equals("héllo+gøodbye")
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
    public void testMultipartPost() throws Exception {
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

        Response result = webServiceProxy.invoke((inputStream, contentType) -> new ObjectMapper().readValue(inputStream, Response.class));

        Assert.assertTrue("POST (multipart)", result.getString().equals("héllo+gøodbye")
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
    public void testCustomPost() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("POST", new URL(serverURL, "test"));

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

        BufferedImage image = webServiceProxy.invoke((inputStream, contentType) -> ImageIO.read(inputStream));

        Assert.assertNotNull("POST (custom)", image);
    }

    @Test
    public void testPut() throws Exception {
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

        String text = webServiceProxy.invoke((inputStream, contentType) -> {
            InputStreamReader inputStreamReader = new InputStreamReader(inputStream);

            StringBuilder textBuilder = new StringBuilder();

            int c;
            while ((c = inputStreamReader.read()) != EOF) {
                textBuilder.append((char)c);
            }

            return textBuilder.toString();
        });

        Assert.assertNotNull("PUT", text);
    }

    @Test
    public void testDelete() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("DELETE", new URL(serverURL, "test"));

        webServiceProxy.setArguments(mapOf(
            entry("id", 101)
        ));

        webServiceProxy.invoke(null);

        Assert.assertTrue("DELETE", true);
    }

    @Test
    public void testUnauthorized() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test/unauthorized"));

        int status;
        try {
            webServiceProxy.invoke(null);

            status = HttpURLConnection.HTTP_OK;
        } catch (WebServiceException exception) {
            status = exception.getStatus();
        }

        Assert.assertEquals("Unauthorized", HttpURLConnection.HTTP_FORBIDDEN, status);
    }

    @Test
    public void testError() throws Exception {
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test/error"));

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
        WebServiceProxy webServiceProxy = new WebServiceProxy("GET", new URL(serverURL, "test"));

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