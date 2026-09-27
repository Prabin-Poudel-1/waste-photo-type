package np.chitwancare.repository;

import java.util.List;
import np.chitwancare.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DepartmentRepository
        extends JpaRepository<Department, Long> {
    List<Department> findByActiveTrueOrderByNameAsc();

    @Query(
            "select count(e) > 0 from Department e "
                    + "where lower(trim(e.name)) = lower(:name) "
                    + "and (:id is null or e.id <> :id)")
    boolean nameExists(
            @Param("name") String name,
            @Param("id") Long id);
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/repository/DepartmentRepository.java from your app here.
