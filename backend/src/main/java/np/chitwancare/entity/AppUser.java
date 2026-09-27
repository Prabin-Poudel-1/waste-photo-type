package np.chitwancare.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.util.*;
import np.chitwancare.enums.*;

@Entity
@Table(name = "app_users")
public class AppUser extends MutableEntity {
  @NotBlank
  @Size(max = 120)
  @Column(name = "name", length = 120, nullable = false)
  private String name;

  @NotBlank
  @Email
  @Size(max = 254)
  @Column(name = "email", length = 254, nullable = false)
  private String email;

  @Column(name = "password_hash", length = 255, nullable = true)
  private String passwordHash;

  @Column(name = "phone", length = 32, nullable = true)
  private String phone;

  @Enumerated(EnumType.STRING)
  @Column(name = "role", length = 20, nullable = false)
  private Role role;

  @Column(nullable = false)
  private boolean active = true;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "department_id")
  private Department department;

  public Department getDepartment() { return department; }
  public void setDepartment(Department value) { department = value; }

  public String getName() {
    return name;
  }

  public void setName(String value) {
    this.name = value;
  }

  public String getEmail() {
    return email;
  }

  public void setEmail(String value) {
    this.email = value;
  }

  public String getPasswordHash() {
    return passwordHash;
  }

  public void setPasswordHash(String value) {
    this.passwordHash = value;
  }

  public String getPhone() {
    return phone;
  }

  public void setPhone(String value) {
    this.phone = value;
  }

  public Role getRole() {
    return role;
  }

  public void setRole(Role value) {
    this.role = value;
  }

  public boolean isActive() {
    return active;
  }

  public void setActive(boolean value) {
    this.active = value;
  }
}
