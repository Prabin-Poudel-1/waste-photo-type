package np.chitwancare.entity;

import jakarta.persistence.*;
import java.util.*;
import np.chitwancare.enums.*;

@Entity
@Table(name = "report_status_history")
public class ReportStatusHistory extends BaseEntity {
  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "report_id", nullable = false)
  private WasteReport report;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", length = 30, nullable = false)
  private ReportStatus status;

  @ManyToOne(fetch = FetchType.LAZY, optional = true)
  @JoinColumn(name = "changed_by_id", nullable = true)
  private AppUser changedBy;

  @Column(name = "note", length = 1000, nullable = true)
  private String note;

  public WasteReport getReport() {
    return report;
  }

  public void setReport(WasteReport value) {
    this.report = value;
  }

  public ReportStatus getStatus() {
    return status;
  }

  public void setStatus(ReportStatus value) {
    this.status = value;
  }

  public AppUser getChangedBy() {
    return changedBy;
  }

  public void setChangedBy(AppUser value) {
    this.changedBy = value;
  }

  public String getNote() {
    return note;
  }

  public void setNote(String value) {
    this.note = value;
  }
}
