package np.chitwancare.controller;

import java.util.List;
import np.chitwancare.dto.TouristSpotResponse;
import np.chitwancare.service.TouristSpotService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/tourist-spots")
public class TouristSpotController {
  private final TouristSpotService service;

  public TouristSpotController(TouristSpotService service) {
    this.service = service;
  }

  @GetMapping
  public List<TouristSpotResponse> list() {
    return service.list();
  }

  @GetMapping("/{id}")
  public TouristSpotResponse get(@PathVariable long id) {
    return service.get(id);
  }

  @GetMapping("/nearest")
  public org.springframework.http.ResponseEntity<TouristSpotResponse> nearest(
      @RequestParam double latitude, @RequestParam double longitude) {
    var match = service.nearest(latitude, longitude);
    return match == null
        ? org.springframework.http.ResponseEntity.noContent().build()
        : org.springframework.http.ResponseEntity.ok(match);
  }
}
