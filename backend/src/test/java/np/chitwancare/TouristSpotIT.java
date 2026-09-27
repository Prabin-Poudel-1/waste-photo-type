package np.chitwancare;

import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;
import java.net.URI;
import java.net.http.*;
import java.util.*;
import np.chitwancare.entity.TouristSpot;
import np.chitwancare.repository.TouristSpotRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.client.RestClient;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class TouristSpotIT {
  @LocalServerPort int port;
  @Autowired TouristSpotRepository spots;
  @Autowired JdbcTemplate jdbc;
  private final HttpClient http = HttpClient.newHttpClient();

  private String url(String path) {
    return "http://127.0.0.1:" + port + "/api/v1" + path;
  }

  private TouristSpot spot(boolean active) {
    var spot = new TouristSpot();
    spot.setName("Development fixture " + UUID.randomUUID());
    spot.setDescription("Synthetic test coordinates, not an official tourist destination");
    spot.setLatitude(new BigDecimal("0.000000"));
    spot.setLongitude(new BigDecimal("0.000000"));
    spot.setRadiusMeters(100);
    spot.setActive(active);
    return spots.saveAndFlush(spot);
  }

  private HttpResponse<String> request(String path) throws Exception {
    return http.send(
        HttpRequest.newBuilder(URI.create(url(path))).GET().build(),
        HttpResponse.BodyHandlers.ofString());
  }

  @SuppressWarnings("unchecked")
  private Map<String, Object> getReport(long id) {
    return RestClient.create().get().uri(url("/reports/" + id)).retrieve().body(Map.class);
  }

  private HttpResponse<String> create(Long spotId) throws Exception {
    long category =
        jdbc.queryForObject("select id from waste_categories where code='plastic'", Long.class);
    String optional = spotId == null ? "" : ",\"touristSpotId\":" + spotId;
    String json =
        "{\"description\":\"Tourist spot"
            + " fixture\",\"latitude\":0.0001,\"longitude\":0.0002,\"severity\":\"MEDIUM\""
            + optional
            + ",\"detections\":[{\"categoryId\":"
            + category
            + ",\"label\":\"Plastic\",\"confidence\":0.94}]}";
    return http.send(
        HttpRequest.newBuilder(URI.create(url("/reports")))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(json))
            .build(),
        HttpResponse.BodyHandlers.ofString());
  }

  private long id(HttpResponse<String> response) {
    assertEquals(201, response.statusCode(), response.body());
    return Long.parseLong(
        response.headers().firstValue("Location").orElseThrow().replace("/api/v1/reports/", ""));
  }

  @Test
  void touristSpotPersistsWithTimestampsAndCoordinates() {
    var spot = spot(true);
    var loaded = spots.findById(spot.getId()).orElseThrow();
    assertEquals(spot.getName(), loaded.getName());
    assertEquals(100, loaded.getRadiusMeters());
    assertEquals(0, loaded.getLatitude().compareTo(BigDecimal.ZERO));
    assertNotNull(loaded.getCreatedAt());
    assertNotNull(loaded.getUpdatedAt());
  }

  @Test
  void nearestEndpointMatchesWithinRadiusAndRejectsInvalidCoordinates() throws Exception {
    spot(true);
    assertEquals(200, request("/tourist-spots/nearest?latitude=0&longitude=0").statusCode());
    assertEquals(204, request("/tourist-spots/nearest?latitude=80&longitude=80").statusCode());
    assertEquals(400, request("/tourist-spots/nearest?latitude=91&longitude=0").statusCode());
    assertEquals(400, request("/tourist-spots/nearest?latitude=NaN&longitude=0").statusCode());
    assertEquals(400, request("/tourist-spots/nearest?latitude=0&longitude=-181").statusCode());
  }

  @Test
  void listReturnsActiveSpotsOnly() throws Exception {
    var active = spot(true);
    var inactive = spot(false);
    var response = request("/tourist-spots");
    assertEquals(200, response.statusCode());
    assertTrue(response.body().contains(active.getName()));
    assertFalse(response.body().contains(inactive.getName()));
  }

  @Test
  void getByIdExposesDestinationDtoAndRejectsMissingOrInactive() throws Exception {
    var spot = spot(true);
    var response = request("/tourist-spots/" + spot.getId());
    assertEquals(200, response.statusCode());
    assertTrue(response.body().contains(spot.getName()));
    assertTrue(response.body().contains("radiusMeters"));
    assertFalse(response.body().contains("reports"));
    assertEquals(404, request("/tourist-spots/9223372036854775807").statusCode());
    assertEquals(404, request("/tourist-spots/" + spot(false).getId()).statusCode());
    assertEquals(400, request("/tourist-spots/0").statusCode());
  }

  @Test
  @SuppressWarnings("unchecked")
  void reportReferencesSpotWithoutChangingExactIncidentCoordinatesOrTimeline() throws Exception {
    var spot = spot(true);
    long id = id(create(spot.getId()));
    var report = getReport(id);
    var summary = (Map<String, Object>) report.get("touristSpot");
    assertEquals(spot.getName(), summary.get("name"));
    assertEquals(spot.getId().longValue(), ((Number) summary.get("id")).longValue());
    assertEquals(2, summary.size());
    assertEquals(.0001, ((Number) report.get("latitude")).doubleValue());
    assertEquals(.0002, ((Number) report.get("longitude")).doubleValue());
    assertEquals(
        spot.getId(),
        jdbc.queryForObject(
            "select tourist_spot_id from waste_reports where id=?", Long.class, id));
    var history = (List<Map<String, Object>>) report.get("statusHistory");
    assertEquals(1, history.size());
    assertEquals("SUBMITTED", history.getFirst().get("status"));
    assertTrue(history.getFirst().containsKey("note"));
    assertNotNull(history.getFirst().get("createdAt"));
  }

  @Test
  void oldReportRequestsRemainCompatible() throws Exception {
    var report = getReport(id(create(null)));
    assertNull(report.get("touristSpot"));
    assertEquals("SUBMITTED", report.get("status"));
  }

  @Test
  void unknownInactiveAndNonpositiveSpotReferencesFailWithoutCreatingReports() throws Exception {
    var inactive = spot(false);
    long count = jdbc.queryForObject("select count(*) from waste_reports", Long.class);
    assertEquals(404, create(Long.MAX_VALUE).statusCode());
    assertEquals(404, create(inactive.getId()).statusCode());
    assertEquals(400, create(0L).statusCode());
    assertEquals(count, jdbc.queryForObject("select count(*) from waste_reports", Long.class));
  }

  @Test
  @SuppressWarnings("unchecked")
  void deactivationPreventsNewAssociationButPreservesHistoricReportDisplay() throws Exception {
    var spot = spot(true);
    long id = id(create(spot.getId()));
    spot.setActive(false);
    spots.saveAndFlush(spot);
    assertEquals(404, create(spot.getId()).statusCode());
    assertEquals(
        spot.getName(), ((Map<String, Object>) getReport(id).get("touristSpot")).get("name"));
  }

  @Test
  void databaseRejectsBlankNameInvalidCoordinatesAndRadius() {
    String sql = "insert into tourist_spots(name,latitude,longitude,radius_meters) values(?,?,?,?)";
    assertThrows(DataIntegrityViolationException.class, () -> jdbc.update(sql, " ", 0, 0, 100));
    assertThrows(DataIntegrityViolationException.class, () -> jdbc.update(sql, "Test", 91, 0, 100));
    assertThrows(
        DataIntegrityViolationException.class, () -> jdbc.update(sql, "Test", 0, -181, 100));
    assertThrows(DataIntegrityViolationException.class, () -> jdbc.update(sql, "Test", 0, 0, 0));
  }
}
