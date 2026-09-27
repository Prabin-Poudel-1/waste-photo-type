package np.chitwancare.repository;

import np.chitwancare.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DepartmentRepository extends JpaRepository<Department, Long> {
  java.util.List<Department> findByActiveTrueOrderByNameAsc();
  @org.springframework.data.jpa.repository.Query("select count(e) > 0 from Department e where lower(trim(e.name)) = lower(:name) and (:id is null or e.id <> :id)")
  boolean nameExists(@org.springframework.data.repository.query.Param("name") String name,
      @org.springframework.data.repository.query.Param("id") Long id);
}
