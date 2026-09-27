package np.chitwancare;

import static org.junit.jupiter.api.Assertions.*;

import java.net.URI;
import java.net.http.*;
import java.util.*;
import np.chitwancare.entity.Department;
import np.chitwancare.repository.DepartmentRepository;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.client.RestClient;

// Run only against a dedicated PostgreSQL database: ./mvnw -Ppostgres-it verify.
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ReportingIT {
  @LocalServerPort int port;
  @Autowired JdbcTemplate jdbc;
  @Autowired DepartmentRepository departments;
  private final HttpClient http = HttpClient.newHttpClient();

  private String url(String path) {
    return "http://127.0.0.1:" + port + "/api/v1" + path;
  }

  private HttpResponse<String> post(String body) throws Exception {
    return http.send(
        HttpRequest.newBuilder(URI.create(url("/reports")))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build(),
        HttpResponse.BodyHandlers.ofString());
  }

  @SuppressWarnings("unchecked")
  private Map<String, Object> get(String path) {
    return RestClient.create().get().uri(url(path)).retrieve().body(Map.class);
  }

  private long category(String code) {
    return jdbc.queryForObject("select id from waste_categories where code=?", Long.class, code);
  }

  private String valid() {
    return """
    {"description":"Development test waste beside a trail","latitude":27.68,"longitude":84.43,"severity":"MEDIUM",
    "detections":[{"categoryId":%d,"label":"Plastic","confidence":0.94},{"categoryId":%d,"label":"Organic","confidence":0.82}]}
    """
        .formatted(category("plastic"), category("organic"));
  }

  @Test
  void contextAndHealthCheckRealDatabase() {
    assertEquals(
        "PostgreSQL",
        jdbc.execute(
            (org.springframework.jdbc.core.ConnectionCallback<String>)
                c -> c.getMetaData().getDatabaseProductName()));
    assertEquals("UP", get("/health").get("database"));
    assertEquals(
        3,
        jdbc.queryForObject(
            "select count(*) from flyway_schema_history where success=true", Integer.class));
  }

  @Test
  void categoryCatalogIsSeededAndActiveOnly() throws Exception {
    var response =
        http.send(
            HttpRequest.newBuilder(URI.create(url("/waste-categories"))).GET().build(),
            HttpResponse.BodyHandlers.ofString());
    assertEquals(200, response.statusCode());
    assertTrue(response.body().contains("Plastic"));
    assertTrue(response.body().contains("Hazardous Waste"));
    assertEquals(10, jdbc.queryForObject("select count(*) from waste_categories", Integer.class));
  }

  @Test
  void departmentsAreDatabaseDriven() throws Exception {
    var d = new Department();
    d.setName("Test department " + UUID.randomUUID());
    d.setActive(true);
    departments.saveAndFlush(d);
    try {
      var response =
          http.send(
              HttpRequest.newBuilder(URI.create(url("/departments"))).GET().build(),
              HttpResponse.BodyHandlers.ofString());
      assertEquals(200, response.statusCode());
      assertTrue(response.body().contains(d.getName()));
      d.setActive(false);
      departments.saveAndFlush(d);
      response =
          http.send(
              HttpRequest.newBuilder(URI.create(url("/departments"))).GET().build(),
              HttpResponse.BodyHandlers.ofString());
      assertFalse(response.body().contains(d.getName()));
    } finally {
      departments.deleteById(d.getId());
    }
  }

  @Test
  void reportCreationStoresDetectionsHistoryAndCanBeRetrieved() throws Exception {
    var response = post(valid());
    assertEquals(201, response.statusCode(), response.body());
    String location = response.headers().firstValue("Location").orElseThrow();
    long id = Long.parseLong(location.substring(location.lastIndexOf('/') + 1));
    var report = get("/reports/" + id);
    assertEquals("SUBMITTED", report.get("status"));
    assertEquals(2, ((List<?>) report.get("detections")).size());
    assertEquals(1, ((List<?>) report.get("statusHistory")).size());
    assertEquals(
        2,
        jdbc.queryForObject(
            "select count(*) from waste_detections where report_id=?", Integer.class, id));
    assertEquals(
        "SUBMITTED",
        jdbc.queryForObject(
            "select status from report_status_history where report_id=?", String.class, id));
    assertNull(
        jdbc.queryForObject("select reporter_id from waste_reports where id=?", Long.class, id));
    assertFalse(response.body().contains("password"));
  }

  @Test
  void paginationIsBounded() throws Exception {
    assertEquals(201, post(valid()).statusCode());
    var page = get("/reports?page=0&size=1");
    assertEquals(1, ((List<?>) page.get("content")).size());
    assertEquals(1, ((Number) page.get("size")).intValue());
    for (String params : List.of("page=-1", "size=101", "size=0", "page=bad")) {
      var response =
          http.send(
              HttpRequest.newBuilder(URI.create(url("/reports?" + params))).GET().build(),
              HttpResponse.BodyHandlers.ofString());
      assertEquals(400, response.statusCode(), response.body());
    }
  }

  @Test
  void invalidLatitudeRejected() throws Exception {
    assertBad(valid().replace("27.68", "91"), "latitude");
  }

  @Test
  void invalidLongitudeRejected() throws Exception {
    assertBad(valid().replace("84.43", "-181"), "longitude");
  }

  @Test
  void invalidConfidenceRejected() throws Exception {
    assertBad(valid().replace("0.94", "1.1"), "confidence");
    assertBad(valid().replace("0.94", "-0.1"), "confidence");
  }

  @Test
  void malformedEnumsNullDetectionsAndExcessPrecisionRejected() throws Exception {
    assertBad(valid().replace("MEDIUM", "URGENT"), "message");
    assertBad("{broken", "message");
    assertBad(valid().replace("27.68", "27.1234567"), "latitude");
    assertBad(
        "{\"latitude\":27,\"longitude\":84,\"severity\":\"LOW\",\"detections\":[null]}",
        "detections");
  }

  @Test
  void unknownCategoryRollsBackWholeReport() throws Exception {
    long before = jdbc.queryForObject("select count(*) from waste_reports", Long.class);
    var response =
        post(
            valid()
                .replace(
                    "\"categoryId\":" + category("organic"), "\"categoryId\":9223372036854775807"));
    assertEquals(404, response.statusCode(), response.body());
    assertEquals(before, jdbc.queryForObject("select count(*) from waste_reports", Long.class));
  }

  @Test
  void inactiveCategoryIsRejected() throws Exception {
    long id = category("glass");
    jdbc.update("update waste_categories set active=false where id=?", id);
    try {
      assertEquals(
          404,
          post(valid().replace("\"categoryId\":" + category("organic"), "\"categoryId\":" + id))
              .statusCode());
    } finally {
      jdbc.update("update waste_categories set active=true where id=?", id);
    }
  }

  @Test
  void missingReportHasConsistentError() throws Exception {
    var response =
        http.send(
            HttpRequest.newBuilder(URI.create(url("/reports/9223372036854775807"))).GET().build(),
            HttpResponse.BodyHandlers.ofString());
    assertEquals(404, response.statusCode());
    assertTrue(response.body().contains("fieldErrors"));
    assertTrue(response.body().contains("timestamp"));
    assertFalse(response.body().contains("stackTrace"));
  }

  @Test
  void databaseProtectsConfidenceAndSingleActiveAssignment() throws Exception {
    var response = post(valid());
    long id =
        Long.parseLong(
            response
                .headers()
                .firstValue("Location")
                .orElseThrow()
                .replace("/api/v1/reports/", ""));
    assertThrows(
        DataIntegrityViolationException.class,
        () ->
            jdbc.update(
                "insert into"
                    + " waste_detections(report_id,waste_category_id,detected_label,confidence)"
                    + " values(?,?,?,?)",
                id,
                category("plastic"),
                "Invalid",
                2));
    var d = new Department();
    d.setName("Assignment test " + UUID.randomUUID());
    departments.saveAndFlush(d);
    try {
      jdbc.update(
          "insert into report_assignments(report_id,department_id,active) values(?,?,true)",
          id,
          d.getId());
      assertThrows(
          DataIntegrityViolationException.class,
          () ->
              jdbc.update(
                  "insert into report_assignments(report_id,department_id,active) values(?,?,true)",
                  id,
                  d.getId()));
      jdbc.update("update report_assignments set active=false where report_id=?", id);
      jdbc.update(
          "insert into report_assignments(report_id,department_id,active) values(?,?,true)",
          id,
          d.getId());
      assertEquals(
          2,
          jdbc.queryForObject(
              "select count(*) from report_assignments where report_id=?", Integer.class, id));
    } finally {
      jdbc.update("delete from report_assignments where report_id=?", id);
      departments.deleteById(d.getId());
    }
  }

  @Test
  void corsAllowsOnlyConfiguredOrigins() throws Exception {
    for (String origin : List.of("http://localhost:5190", "https://untrusted.example")) {
      var response =
          http.send(
              HttpRequest.newBuilder(URI.create(url("/reports")))
                  .header("Origin", origin)
                  .header("Access-Control-Request-Method", "POST")
                  .method("OPTIONS", HttpRequest.BodyPublishers.noBody())
                  .build(),
              HttpResponse.BodyHandlers.ofString());
      if (origin.contains("localhost"))
        assertEquals(
            origin, response.headers().firstValue("Access-Control-Allow-Origin").orElseThrow());
      else assertTrue(response.headers().firstValue("Access-Control-Allow-Origin").isEmpty());
    }
  }

  private void assertBad(String json, String field) throws Exception {
    var response = post(json);
    assertEquals(400, response.statusCode(), response.body());
    assertTrue(response.body().contains(field), response.body());
  }
}
