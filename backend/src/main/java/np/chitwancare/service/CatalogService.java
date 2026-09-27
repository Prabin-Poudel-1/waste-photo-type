package np.chitwancare.service;

import java.util.List;
import np.chitwancare.dto.*;
import np.chitwancare.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class CatalogService {
  private final WasteCategoryRepository categories;
  private final DepartmentRepository departments;

  public CatalogService(WasteCategoryRepository categories, DepartmentRepository departments) {
    this.categories = categories;
    this.departments = departments;
  }

  public List<WasteCategoryResponse> categories() {
    return categories.findByActiveTrueOrderByNameAsc().stream()
        .map(
            c -> new WasteCategoryResponse(c.getId(), c.getCode(), c.getName(), c.getDescription()))
        .toList();
  }

  public List<DepartmentResponse> departments() {
    return departments.findByActiveTrueOrderByNameAsc().stream()
        .map(
            d ->
                new DepartmentResponse(
                    d.getId(),
                    d.getName(),
                    d.getDescription(),
                    d.getContactEmail(),
                    d.getContactPhone()))
        .toList();
  }
}
