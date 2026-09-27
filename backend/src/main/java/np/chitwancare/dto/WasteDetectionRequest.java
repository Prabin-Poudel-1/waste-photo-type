package np.chitwancare.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record WasteDetectionRequest(
        @NotNull
        @Positive
        Long categoryId,
        @NotBlank
        @Size(max = 100)
        String label,
        @NotNull
        @DecimalMin("0")
        @DecimalMax("1")
        @Digits(integer = 1, fraction = 6)
        BigDecimal confidence) {}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/dto/WasteDetectionRequest.java from your app here.
