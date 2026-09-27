package np.chitwancare.dto;

import java.math.BigDecimal;

public record WasteDetectionResponse(
        Long id,
        Long categoryId,
        String categoryName,
        String label,
        BigDecimal confidence) {}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/dto/WasteDetectionResponse.java from your app here.
