package np.chitwancare.entity;

import jakarta.persistence.*;
import java.time.Instant;

@MappedSuperclass
public abstract class MutableEntity extends BaseEntity {
  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @PrePersist
  @PreUpdate
  protected void onUpdate() {
    updatedAt = Instant.now();
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
