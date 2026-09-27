package np.chitwancare.repository;

import np.chitwancare.entity.WasteCategory;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WasteCategoryRepository extends JpaRepository<WasteCategory, Long> {
  java.util.List<WasteCategory> findByActiveTrueOrderByNameAsc();

  java.util.List<WasteCategory> findByIdInAndActiveTrue(java.util.Collection<Long> ids);
}
