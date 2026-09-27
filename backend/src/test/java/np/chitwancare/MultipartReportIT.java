package np.chitwancare;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.awt.image.BufferedImage;
import java.io.*;
import java.math.BigDecimal;
import java.net.URI;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import javax.imageio.ImageIO;
import np.chitwancare.entity.*;
import np.chitwancare.repository.*;
import np.chitwancare.storage.ImageStorage;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.web.client.RestClient;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class MultipartReportIT {
  static final Path storage;

  static {
    try {
      storage = Files.createTempDirectory("chitwan-upload-it-");
    } catch (IOException ex) {
      throw new ExceptionInInitializerError(ex);
    }
  }

  @DynamicPropertySource
  static void config(DynamicPropertyRegistry r) {
    r.add("app.storage.directory", () -> storage.toString());
  }

  @AfterAll
  static void cleanup() throws IOException {
    try (var paths = Files.walk(storage)) {
      for (Path p : paths.sorted(Comparator.reverseOrder()).toList()) Files.deleteIfExists(p);
    }
  }

  @LocalServerPort int port;
  @Autowired JdbcTemplate jdbc;
  @jakarta.persistence.PersistenceContext jakarta.persistence.EntityManager entityManager;
  @Autowired TouristSpotRepository spots;
  @MockitoSpyBean ImageStorage images;
  @MockitoSpyBean WasteReportRepository reports;
  final HttpClient http = HttpClient.newHttpClient();

  String url(String p) {
    return "http://127.0.0.1:" + port + "/api/v1" + p;
  }

  byte[] photo() throws IOException {
    var out = new ByteArrayOutputStream();
    ImageIO.write(new BufferedImage(12, 12, BufferedImage.TYPE_INT_RGB), "png", out);
    return out.toByteArray();
  }

  String metadata(Long spot) {
    long category =
        jdbc.queryForObject("select id from waste_categories where code='plastic'", Long.class);
    return "{\"description\":\"Phase 3"
               + " test\",\"latitude\":0.000123,\"longitude\":0.000234,\"severity\":\"HIGH\","
        + (spot == null ? "" : "\"touristSpotId\":" + spot + ",")
        + "\"detections\":[{\"categoryId\":"
        + category
        + ",\"label\":\"Plastic\",\"confidence\":0.94},"
        + "{\"categoryId\":"
        + category
        + ",\"label\":\"Original label\",\"confidence\":0.42}]}";
  }

  HttpResponse<String> upload(String json, byte[] bytes, String type) throws Exception {
    String boundary = "test-" + UUID.randomUUID();
    var body = new ByteArrayOutputStream();
    body.write(
        ("--"
                + boundary
                + "\r\n"
                + "Content-Disposition: form-data; name=\"metadata\"\r\n"
                + "Content-Type: application/json\r\n\r\n"
                + json
                + "\r\n--"
                + boundary
                + "\r\n"
                + "Content-Disposition: form-data; name=\"image\"; filename=\"../../scene.png\"\r\n"
                + "Content-Type: "
                + type
                + "\r\n\r\n")
            .getBytes(StandardCharsets.UTF_8));
    body.write(bytes);
    body.write(("\r\n--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8));
    return http.send(
        HttpRequest.newBuilder(URI.create(url("/reports")))
            .header("Content-Type", "multipart/form-data; boundary=" + boundary)
            .POST(HttpRequest.BodyPublishers.ofByteArray(body.toByteArray()))
            .build(),
        HttpResponse.BodyHandlers.ofString());
  }

  @SuppressWarnings("unchecked")
  Map<String, Object> report(long id) {
    return RestClient.create().get().uri(url("/reports/" + id)).retrieve().body(Map.class);
  }

  long count(String table) {
    return jdbc.queryForObject("select count(*) from " + table, Long.class);
  }

  long fileCount() throws IOException {
    try (var s = Files.list(storage)) {
      return s.count();
    }
  }

  TouristSpot fixture() {
    var s = new TouristSpot();
    s.setName("Development upload fixture " + UUID.randomUUID());
    s.setLatitude(BigDecimal.ZERO);
    s.setLongitude(BigDecimal.ZERO);
    s.setRadiusMeters(100);
    s.setActive(true);
    return spots.saveAndFlush(s);
  }

  @Test
  @SuppressWarnings("unchecked")
  void multipartPersistsWholeReportAndRetrievesExactImage() throws Exception {
    var spot = fixture();
    var bytes = photo();
    var response = upload(metadata(spot.getId()), bytes, "image/png");
    assertEquals(201, response.statusCode(), response.body());
    long id =
        Long.parseLong(
            response
                .headers()
                .firstValue("Location")
                .orElseThrow()
                .replace("/api/v1/reports/", ""));
    var r = report(id);
    assertEquals("SUBMITTED", r.get("status"));
    assertEquals(.000123, ((Number) r.get("latitude")).doubleValue());
    assertEquals(.000234, ((Number) r.get("longitude")).doubleValue());
    assertEquals(spot.getName(), ((Map<?, ?>) r.get("touristSpot")).get("name"));
    assertEquals(2, ((List<?>) r.get("detections")).size());
    assertEquals(1, ((List<?>) r.get("statusHistory")).size());
    var image = ((List<Map<String, Object>>) r.get("images")).getFirst();
    assertEquals("ORIGINAL", image.get("imageType"));
    assertEquals("scene.png", image.get("originalFilename"));
    assertFalse(image.containsKey("storageKey"));
    long imageId = ((Number) image.get("id")).longValue();
    var key =
        jdbc.queryForObject(
            "select storage_key from report_images where id=?", String.class, imageId);
    assertArrayEquals(bytes, Files.readAllBytes(storage.resolve(key)));
    var download =
        http.send(
            HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + port + image.get("url")))
                .build(),
            HttpResponse.BodyHandlers.ofByteArray());
    assertEquals(200, download.statusCode());
    assertEquals("image/png", download.headers().firstValue("Content-Type").orElseThrow());
    assertArrayEquals(bytes, download.body());
    var wrong =
        http.send(
            HttpRequest.newBuilder(
                    URI.create(url("/reports/9223372036854775807/images/" + imageId)))
                .build(),
            HttpResponse.BodyHandlers.ofString());
    assertEquals(404, wrong.statusCode());
  }

  @Test
  void invalidImagesCreateNeitherRowsNorFiles() throws Exception {
    long rows = count("waste_reports"), files = fileCount();
    assertEquals(400, upload(metadata(null), new byte[0], "image/png").statusCode());
    assertEquals(400, upload(metadata(null), "<svg/>".getBytes(), "image/svg+xml").statusCode());
    assertEquals(400, upload(metadata(null), "fake".getBytes(), "image/png").statusCode());
    assertEquals(400, upload(metadata(null), photo(), "image/jpeg").statusCode());
    assertEquals(rows, count("waste_reports"));
    assertEquals(files, fileCount());
  }

  @Test
  void oversizedImageRejected() throws Exception {
    long rows = count("waste_reports");
    assertEquals(
        413, upload(metadata(null), new byte[10 * 1024 * 1024 + 1], "image/png").statusCode());
    assertEquals(rows, count("waste_reports"));
  }

  @Test
  void invalidMetadataNeverStoresImage() throws Exception {
    long rows = count("waste_reports"), files = fileCount();
    assertEquals(
        400, upload(metadata(null).replace("0.000123", "91"), photo(), "image/png").statusCode());
    assertEquals(
        400, upload(metadata(null).replace("0.94", "1.01"), photo(), "image/png").statusCode());
    assertEquals(404, upload(metadata(Long.MAX_VALUE), photo(), "image/png").statusCode());
    assertEquals(
        404,
        upload(
                metadata(null)
                    .replaceAll("\"categoryId\":[0-9]+", "\"categoryId\":9223372036854775807"),
                photo(),
                "image/png")
            .statusCode());
    var s = fixture();
    s.setActive(false);
    spots.saveAndFlush(s);
    assertEquals(404, upload(metadata(s.getId()), photo(), "image/png").statusCode());
    assertEquals(rows, count("waste_reports"));
    assertEquals(files, fileCount());
  }

  @Test
  void storageFailureRollsBackReport() throws Exception {
    long rows = count("waste_reports");
    doThrow(new IOException("test failure"))
        .when(images)
        .store(any(), anyString(), anyString(), anyLong());
    assertEquals(503, upload(metadata(null), photo(), "image/png").statusCode());
    assertEquals(rows, count("waste_reports"));
  }

  @Test
  void databaseFailureCleansStoredFile() throws Exception {
    long rows = count("waste_reports"), files = fileCount();
    doAnswer(invocation -> {
          entityManager.persist(invocation.getArgument(0));
          entityManager.flush();
          throw new org.springframework.dao.DataIntegrityViolationException("test failure after flush");
        })
        .when(reports)
        .saveAndFlush(any(WasteReport.class));
    assertEquals(409, upload(metadata(null), photo(), "image/png").statusCode());
    assertEquals(rows, count("waste_reports"));
    assertEquals(files, fileCount());
  }
}
