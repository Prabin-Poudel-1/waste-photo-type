package np.chitwancare.dto;

import java.math.BigDecimal;

public record WasteDetectionResponse(
    Long id, Long categoryId, String categoryName, String label, BigDecimal confidence) {}
