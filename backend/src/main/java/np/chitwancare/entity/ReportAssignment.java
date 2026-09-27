package np.chitwancare.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "report_assignments")
public class ReportAssignment {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "report_id", nullable = false)
  private WasteReport report;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "department_id", nullable = false)
  private Department department;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "assigned_by_id")
  private AppUser assignedBy;

  @Column(name = "assigned_at", nullable = false, updatable = false)
  private Instant assignedAt;

  @Column(nullable = false)
  private boolean active = true;

  @PrePersist
  void assigned() {
    if (assignedAt == null) assignedAt = Instant.now();
  }

  public Long getId() {
    return id;
  }

  public WasteReport getReport() {
    return report;
  }

  public void setReport(WasteReport value) {
    report = value;
  }

  public Department getDepartment() {
    return department;
  }

  public void setDepartment(Department value) {
    department = value;
  }

  public AppUser getAssignedBy() {
    return assignedBy;
  }

  public void setAssignedBy(AppUser value) {
    assignedBy = value;
  }

  public Instant getAssignedAt() {
    return assignedAt;
  }

  public boolean isActive() {
    return active;
  }

  public void setActive(boolean value) {
    active = value;
  }
}
