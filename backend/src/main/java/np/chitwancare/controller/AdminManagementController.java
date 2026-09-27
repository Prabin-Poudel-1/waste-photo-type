package np.chitwancare.controller;

import jakarta.validation.Valid;
import java.util.List;
import np.chitwancare.service.AdminManagementService;
import np.chitwancare.dto.AdminManagementDtos.*;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/management")
public class AdminManagementController {
  private final AdminManagementService service;
  public AdminManagementController(AdminManagementService service) { this.service = service; }
  @GetMapping("/departments")
  public List<DepartmentView> departments() { return service.departments(); }
  @PostMapping("/departments") @ResponseStatus(HttpStatus.CREATED)
  public DepartmentView createDepartment(@Valid @RequestBody DepartmentInput input) { return service.saveDepartment(null, input); }
  @PutMapping("/departments/{id}")
  public DepartmentView updateDepartment(@PathVariable long id, @Valid @RequestBody DepartmentInput input) { return service.saveDepartment(id, input); }
  @GetMapping("/tourist-spots")
  public List<SpotView> spots() { return service.spots(); }
  @PostMapping("/tourist-spots") @ResponseStatus(HttpStatus.CREATED)
  public SpotView createSpot(@Valid @RequestBody SpotInput input) { return service.saveSpot(null, input); }
  @PutMapping("/tourist-spots/{id}")
  public SpotView updateSpot(@PathVariable long id, @Valid @RequestBody SpotInput input) { return service.saveSpot(id, input); }
}
