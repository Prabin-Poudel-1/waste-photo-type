package np.chitwancare.repository;

import java.util.Collection;
import java.util.List;
import np.chitwancare.entity.WasteCategory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WasteCategoryRepository
        extends JpaRepository<WasteCategory, Long> {
    List<WasteCategory> findByActiveTrueOrderByNameAsc();

    List<WasteCategory> findByIdInAndActiveTrue(
            Collection<Long> ids);
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/repository/WasteCategoryRepository.java from your app here.
