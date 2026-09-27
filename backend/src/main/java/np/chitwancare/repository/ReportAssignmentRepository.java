package np.chitwancare.repository;

import java.util.List;
import np.chitwancare.entity.ReportAssignment;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportAssignmentRepository
        extends JpaRepository<ReportAssignment, Long> {
    boolean existsByReportIdAndDepartmentIdAndActiveTrue(
            Long reportId,
            Long departmentId);

    List<ReportAssignment> findByReportIdAndActiveTrue(
            Long reportId);
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/repository/ReportAssignmentRepository.java from your app here.
