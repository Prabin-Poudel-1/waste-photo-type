package np.chitwancare.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import np.chitwancare.enums.Severity;

public record CreateWasteReportRequest(
        @Size(max = 2000)
        String description,
        @NotNull
        @DecimalMin("-90")
        @DecimalMax("90")
        @Digits(integer = 3, fraction = 6)
        BigDecimal latitude,
        @NotNull
        @DecimalMin("-180")
        @DecimalMax("180")
        @Digits(integer = 3, fraction = 6)
        BigDecimal longitude,
        @Size(max = 500)
        String address,
        @NotNull
        Severity severity,
        @Positive
        Long touristSpotId,
        @NotNull
        @Size(min = 1, max = 20)
        List<@NotNull @Valid WasteDetectionRequest> detections) {}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/dto/CreateWasteReportRequest.java from your app here.
