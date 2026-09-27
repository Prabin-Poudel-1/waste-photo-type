package np.chitwancare.controller;
import np.chitwancare.service.LocationInsightsService;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api/v1")
public class LocationInsightsController {
  private final LocationInsightsService service;
  public LocationInsightsController(LocationInsightsService service) { this.service=service; }
  @GetMapping("/maps/reports")
  public LocationInsightsService.MapPage map(@RequestParam double south,@RequestParam double west,
      @RequestParam double north,@RequestParam double east,@RequestParam(defaultValue="ALL") String filter) {
    return service.map(south,west,north,east,filter);
  }
  @GetMapping("/authority/insights")
  public LocationInsightsService.Insights insights() { return service.insights(); }
}
