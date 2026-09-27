package np.chitwancare.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public final class AdminManagementDtos {
  private AdminManagementDtos() {}
  public record DepartmentInput(@NotBlank @Size(max=150) String name,
      @Size(max=1000) String description, @NotNull Boolean active) {}
  public record SpotInput(@NotBlank @Size(max=150) String name,
      @Size(max=2000) String description,
      @NotNull @DecimalMin("-90") @DecimalMax("90") @Digits(integer=3,fraction=6) BigDecimal latitude,
      @NotNull @DecimalMin("-180") @DecimalMax("180") @Digits(integer=3,fraction=6) BigDecimal longitude,
      @NotNull @Positive Integer radiusMeters, @Size(max=500) String address, @NotNull Boolean active) {}
  public record DepartmentView(Long id, String name, String description, boolean active) {}
  public record SpotView(Long id, String name, String description, BigDecimal latitude,
      BigDecimal longitude, Integer radiusMeters, String address, boolean active) {}

}
