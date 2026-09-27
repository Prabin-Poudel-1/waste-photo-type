package np.chitwancare.entity;

import jakarta.persistence.*;
import java.util.*;
import np.chitwancare.enums.*;

@Entity
@Table(name = "waste_categories")
public class WasteCategory extends MutableEntity {
  @Column(name = "code", length = 60, nullable = false)
  private String code;

  @Column(name = "name", length = 100, nullable = false)
  private String name;

  @Column(name = "description", length = 500, nullable = true)
  private String description;

  @Column(nullable = false)
  private boolean active = true;

  public String getCode() {
    return code;
  }

  public void setCode(String value) {
    this.code = value;
  }

  public String getName() {
    return name;
  }

  public void setName(String value) {
    this.name = value;
  }

  public String getDescription() {
    return description;
  }

  public void setDescription(String value) {
    this.description = value;
  }

  public boolean isActive() {
    return active;
  }

  public void setActive(boolean value) {
    this.active = value;
  }
}
