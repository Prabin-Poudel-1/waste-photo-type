package np.chitwancare.entity;

import jakarta.persistence.*;
import java.util.*;
import np.chitwancare.enums.*;

@Entity
@Table(name = "routing_rules")
public class RoutingRule extends MutableEntity {
  @ManyToOne(fetch = FetchType.LAZY, optional = true)
  @JoinColumn(name = "waste_category_id", nullable = true)
  private WasteCategory wasteCategory;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "department_id", nullable = false)
  private Department department;

  @Column(name = "area_identifier", length = 120, nullable = true)
  private String areaIdentifier;

  @Column(nullable = false)
  private int priority = 0;

  @Column(nullable = false)
  private boolean active = true;

  public WasteCategory getWasteCategory() {
    return wasteCategory;
  }

  public void setWasteCategory(WasteCategory value) {
    this.wasteCategory = value;
  }

  public Department getDepartment() {
    return department;
  }

  public void setDepartment(Department value) {
    this.department = value;
  }

  public String getAreaIdentifier() {
    return areaIdentifier;
  }

  public void setAreaIdentifier(String value) {
    this.areaIdentifier = value;
  }

  public int getPriority() {
    return priority;
  }

  public void setPriority(int value) {
    this.priority = value;
  }

  public boolean isActive() {
    return active;
  }

  public void setActive(boolean value) {
    this.active = value;
  }
}
