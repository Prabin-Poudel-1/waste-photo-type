package np.chitwancare.controller;

import java.util.List;
import np.chitwancare.dto.TouristSpotResponse;
import np.chitwancare.service.TouristSpotService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/tourist-spots")
public class TouristSpotController {
    private final TouristSpotService service;

    public TouristSpotController(
            TouristSpotService service) {
        this.service = service;
    }

    @GetMapping
    public List<TouristSpotResponse> list() {
        return service.list();
    }

    @GetMapping("/{id}")
    public TouristSpotResponse get(
            @PathVariable long id) {
        return service.get(id);
    }

    @GetMapping("/nearest")
    public ResponseEntity<TouristSpotResponse> nearest(
            @RequestParam double latitude,
            @RequestParam double longitude) {
        var match =
                service.nearest(latitude, longitude);

        return match == null
                ? ResponseEntity.noContent().build()
                : ResponseEntity.ok(match);
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/controller/TouristSpotController.java from your app here.
