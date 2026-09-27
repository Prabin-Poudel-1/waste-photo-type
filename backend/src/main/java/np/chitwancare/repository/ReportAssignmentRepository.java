package np.chitwancare.repository;

import np.chitwancare.entity.ReportAssignment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportAssignmentRepository extends JpaRepository<ReportAssignment, Long> {
  boolean existsByReportIdAndDepartmentIdAndActiveTrue(Long reportId, Long departmentId);
  java.util.List<ReportAssignment> findByReportIdAndActiveTrue(Long reportId);
}
