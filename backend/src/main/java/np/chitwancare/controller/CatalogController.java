package np.chitwancare.controller;

import java.util.List;
import np.chitwancare.dto.DepartmentResponse;
import np.chitwancare.dto.WasteCategoryResponse;
import np.chitwancare.service.CatalogService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class CatalogController {
    private final CatalogService service;

    public CatalogController(
            CatalogService service) {
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
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/controller/CatalogController.java from your app here.
