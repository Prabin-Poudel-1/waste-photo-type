package np.chitwancare.service;

import java.util.List;
import np.chitwancare.dto.DepartmentResponse;
import np.chitwancare.dto.WasteCategoryResponse;
import np.chitwancare.repository.DepartmentRepository;
import np.chitwancare.repository.WasteCategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class CatalogService {
    private final WasteCategoryRepository categories;
    private final DepartmentRepository departments;

    public CatalogService(
            WasteCategoryRepository categories,
            DepartmentRepository departments) {
        this.categories = categories;
        this.departments = departments;
    }

    public List<WasteCategoryResponse> categories() {
        return categories
                .findByActiveTrueOrderByNameAsc()
                .stream()
                .map(
                        category ->
                                new WasteCategoryResponse(
                                        category.getId(),
                                        category.getCode(),
                                        category.getName(),
                                        category.getDescription()))
                .toList();
    }

    public List<DepartmentResponse> departments() {
        return departments
                .findByActiveTrueOrderByNameAsc()
                .stream()
                .map(
                        department ->
                                new DepartmentResponse(
                                        department.getId(),
                                        department.getName(),
                                        department.getDescription(),
                                        department.getContactEmail(),
                                        department.getContactPhone()))
                .toList();
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/service/CatalogService.java from your app here.
