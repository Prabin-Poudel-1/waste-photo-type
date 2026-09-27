package np.chitwancare.controller;

import java.util.List;
import np.chitwancare.dto.*;
import np.chitwancare.service.CatalogService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class CatalogController {
  private final CatalogService service;

  public CatalogController(CatalogService service) {
    this.service = service;
  }

  @GetMapping("/waste-categories")
  public List<WasteCategoryResponse> categories() {
    return service.categories();
  }

  @GetMapping("/departments")
  public List<DepartmentResponse> departments() {
    return service.departments();
  }
}
