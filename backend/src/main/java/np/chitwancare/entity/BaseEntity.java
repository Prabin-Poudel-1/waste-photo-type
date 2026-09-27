package np.chitwancare.entity;

import jakarta.persistence.*;
import java.time.Instant;

@MappedSuperclass
public abstract class BaseEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @PrePersist
  protected void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public Long getId() {
    return id;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
