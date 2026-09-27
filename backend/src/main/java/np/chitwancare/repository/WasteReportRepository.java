package np.chitwancare.repository;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import np.chitwancare.entity.WasteReport;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface WasteReportRepository
        extends JpaRepository<WasteReport, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query(
            "select r from WasteReport r "
                    + "where r.id = :id")
    Optional<WasteReport> findForUpdate(
            @Param("id") Long id);

    @Query(
            "select r from WasteReport r "
                    + "where exists ("
                    + "select a.id from ReportAssignment a "
                    + "where a.report = r "
                    + "and a.active = true "
                    + "and a.department.id = :departmentId)")
    Page<WasteReport> findAssigned(
            @Param("departmentId") Long departmentId,
            Pageable page);

    Page<WasteReport> findByReporterId(
            Long reporterId,
            Pageable page);
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/repository/WasteReportRepository.java from your app here.
