package np.chitwancare.repository;

import np.chitwancare.entity.WasteReport;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WasteReportRepository extends JpaRepository<WasteReport, Long> {
  @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
  @org.springframework.data.jpa.repository.Query("select r from WasteReport r where r.id = :id")
  java.util.Optional<WasteReport> findForUpdate(@org.springframework.data.repository.query.Param("id") Long id);
  @org.springframework.data.jpa.repository.Query("select r from WasteReport r where exists (select a.id from ReportAssignment a where a.report = r and a.active = true and a.department.id = :departmentId)")
  org.springframework.data.domain.Page<WasteReport> findAssigned(
      @org.springframework.data.repository.query.Param("departmentId") Long departmentId, org.springframework.data.domain.Pageable page);
  org.springframework.data.domain.Page<WasteReport> findByReporterId(Long reporterId, org.springframework.data.domain.Pageable page);
}
