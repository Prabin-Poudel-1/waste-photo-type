package np.chitwancare.dto;

import java.math.BigDecimal;

public record TouristSpotResponse(
        Long id,
        String name,
        String description,
        BigDecimal latitude,
        BigDecimal longitude,
        Integer radiusMeters,
        String address) {}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/dto/TouristSpotResponse.java from your app here.
