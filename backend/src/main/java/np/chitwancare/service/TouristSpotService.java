package np.chitwancare.service;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Positive;
import java.util.Comparator;
import java.util.List;
import np.chitwancare.dto.TouristSpotResponse;
import np.chitwancare.entity.TouristSpot;
import np.chitwancare.exception.ResourceNotFoundException;
import np.chitwancare.repository.TouristSpotRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

// Match only registered active destinations whose radius contains the incident.
@Service
@Validated
@Transactional(readOnly = true)
public class TouristSpotService {
    private final TouristSpotRepository spots;

    public TouristSpotService(
            TouristSpotRepository spots) {
        this.spots = spots;
    }

    public List<TouristSpotResponse> list() {
        return spots
                .findByActiveTrueOrderByNameAscIdAsc()
                .stream()
                .map(this::response)
                .toList();
    }

    public TouristSpotResponse get(
            @Positive long id) {
        return response(requireActive(id));
    }

    public TouristSpotResponse nearest(
            @DecimalMin("-90")
            @DecimalMax("90")
            double latitude,
            @DecimalMin("-180")
            @DecimalMax("180")
            double longitude) {
        return spots
                .findByActiveTrueOrderByNameAscIdAsc()
                .stream()
                .filter(
                        spot ->
                                distance(
                                        latitude,
                                        longitude,
                                        spot.getLatitude()
                                                .doubleValue(),
                                        spot.getLongitude()
                                                .doubleValue())
                                        <= spot.getRadiusMeters())
                .min(
                        Comparator
                                .comparingDouble(
                                        (TouristSpot spot) ->
                                                distance(
                                                        latitude,
                                                        longitude,
                                                        spot.getLatitude()
                                                                .doubleValue(),
                                                        spot.getLongitude()
                                                                .doubleValue()))
                                .thenComparing(
                                        TouristSpot::getId))
                .map(this::response)
                .orElse(null);
    }

    public static double distance(
            double lat1,
            double lon1,
            double lat2,
            double lon2) {
        double latitude =
                Math.toRadians(lat2 - lat1);

        double longitude =
                Math.toRadians(lon2 - lon1);

        double value =
                Math.pow(
                        Math.sin(latitude / 2),
                        2)
                        + Math.cos(
                        Math.toRadians(lat1))
                        * Math.cos(
                        Math.toRadians(lat2))
                        * Math.pow(
                        Math.sin(longitude / 2),
                        2);

        return 6_371_000
                * 2
                * Math.asin(
                Math.sqrt(
                        Math.min(
                                1,
                                Math.max(0, value))));
    }

    public TouristSpot requireActive(
            @Positive long id) {
        return spots
                .findByIdAndActiveTrue(id)
                .orElseThrow(
                        () ->
                                new ResourceNotFoundException(
                                        "Tourist spot not found or inactive."));
    }

    private TouristSpotResponse response(
            TouristSpot spot) {
        return new TouristSpotResponse(
                spot.getId(),
                spot.getName(),
                spot.getDescription(),
                spot.getLatitude(),
                spot.getLongitude(),
                spot.getRadiusMeters(),
                spot.getAddress());
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/service/TouristSpotService.java from your app here.
