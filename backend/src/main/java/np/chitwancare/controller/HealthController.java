package np.chitwancare.controller;

import java.util.Map;
import np.chitwancare.service.HealthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
public class HealthController {
  private final HealthService health;

  public HealthController(HealthService health) {
    this.health = health;
  }

  @GetMapping("/api/v1/health")
  public ResponseEntity<Map<String, String>> health() {
    boolean up = health.databaseAvailable();
    return ResponseEntity.status(up ? 200 : 503)
        .body(Map.of("status", up ? "UP" : "DOWN", "database", up ? "UP" : "DOWN"));
  }
}
