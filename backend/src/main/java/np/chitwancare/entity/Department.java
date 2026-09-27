package np.chitwancare.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.util.*;
import np.chitwancare.enums.*;

@Entity
@Table(name = "departments")
public class Department extends MutableEntity {
  @NotBlank
  @Size(max = 150)
  @Column(name = "name", length = 150, nullable = false)
  private String name;

  @Column(name = "description", length = 1000, nullable = true)
  private String description;

  @Email
  @Size(max = 254)
  @Column(name = "contact_email", length = 254, nullable = true)
  private String contactEmail;

  @Column(name = "contact_phone", length = 32, nullable = true)
  private String contactPhone;

  @Column(nullable = false)
  private boolean active = true;

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

  public String getContactEmail() {
    return contactEmail;
  }

  public void setContactEmail(String value) {
    this.contactEmail = value;
  }

  public String getContactPhone() {
    return contactPhone;
  }

  public void setContactPhone(String value) {
    this.contactPhone = value;
  }

  public boolean isActive() {
    return active;
  }

  public void setActive(boolean value) {
    this.active = value;
  }
}
