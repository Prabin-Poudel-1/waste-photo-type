package np.chitwancare.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record WasteDetectionRequest(
    @NotNull @Positive Long categoryId,
    @NotBlank @Size(max = 100) String label,
    @NotNull @DecimalMin("0") @DecimalMax("1") @Digits(integer = 1, fraction = 6)
        BigDecimal confidence) {}
