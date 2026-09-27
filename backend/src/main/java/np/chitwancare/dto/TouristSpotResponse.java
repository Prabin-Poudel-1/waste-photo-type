package np.chitwancare.dto;

import java.math.BigDecimal;

public record TouristSpotResponse(
    Long id,
    String name,
    String description,
    BigDecimal latitude,
    BigDecimal longitude,
    Integer radiusMeters,
    String address) {}
