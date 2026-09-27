package np.chitwancare.analysis;

import static np.chitwancare.analysis.DetectionResult.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class MockWasteDetectionService implements WasteDetectionService {
  public DetectionResult analyze(byte[] image, String scenario) {
    List<Detection> detections =
        switch (scenario) {
          case "multiple" ->
              List.of(
                  new Detection("plastic", "Plastic", 0.94),
                  new Detection("organic", "Organic", 0.82),
                  new Detection("paper", "Paper / cardboard", 0.71));
          case "none" -> List.of();
          case "low" -> List.of(new Detection("mixed", "Mixed waste", 0.43));
          case "error" ->
              throw new ResponseStatusException(
                  HttpStatus.SERVICE_UNAVAILABLE,
                  "Simulated analysis outage. Your photo is still available; choose another demo"
                      + " scenario and retry.");
          default ->
              throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unknown demo scenario.");
        };
    return new DetectionResult(
        UUID.randomUUID().toString(),
        "COMPLETED",
        1,
        "mock-v1",
        true,
        !detections.isEmpty(),
        detections,
        Instant.now());
  }
}
