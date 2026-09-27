package np.chitwancare;

import static org.junit.jupiter.api.Assertions.*;

import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.server.context.WebServerApplicationContext;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.client.RestClient;

class RestartPersistenceIT {
  @Test
  @SuppressWarnings("unchecked")
  void reportSurvivesApplicationRestart() {
    Map<String, Object> created;
    try (var first = new SpringApplicationBuilder(CareApplication.class).run("--server.port=0")) {
      var jdbc = first.getBean(JdbcTemplate.class);
      long plastic =
          jdbc.queryForObject("select id from waste_categories where code='plastic'", Long.class);
      long organic =
          jdbc.queryForObject("select id from waste_categories where code='organic'", Long.class);
      int port = ((WebServerApplicationContext) first).getWebServer().getPort();
      created =
          RestClient.create("http://127.0.0.1:" + port)
              .post()
              .uri("/api/v1/reports")
              .body(
                  Map.of(
                      "description",
                      "Restart persistence test",
                      "latitude",
                      27.68,
                      "longitude",
                      84.43,
                      "severity",
                      "LOW",
                      "detections",
                      List.of(
                          Map.of("categoryId", plastic, "label", "Plastic", "confidence", .94),
                          Map.of("categoryId", organic, "label", "Organic", "confidence", .82))))
              .retrieve()
              .body(Map.class);
      assertNotNull(created);
    }
    // Entire Spring/Tomcat/JPA context is closed and recreated; PostgreSQL is unchanged.
    try (var second = new SpringApplicationBuilder(CareApplication.class).run("--server.port=0")) {
      int port = ((WebServerApplicationContext) second).getWebServer().getPort();
      var restored =
          RestClient.create("http://127.0.0.1:" + port)
              .get()
              .uri("/api/v1/reports/" + created.get("id"))
              .retrieve()
              .body(Map.class);
      assertEquals(created, restored);
      assertEquals(2, ((List<?>) restored.get("detections")).size());
      assertEquals(1, ((List<?>) restored.get("statusHistory")).size());
    }
  }
}
