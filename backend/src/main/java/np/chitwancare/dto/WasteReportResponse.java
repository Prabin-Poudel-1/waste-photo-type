package np.chitwancare.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import np.chitwancare.enums.ReportStatus;
import np.chitwancare.enums.Severity;

public record WasteReportResponse(
        Long id,
        String description,
        BigDecimal latitude,
        BigDecimal longitude,
        String address,
        Severity severity,
        ReportStatus status,
        TouristSpotSummary touristSpot,
        List<WasteDetectionResponse> detections,
        List<StatusHistoryResponse> statusHistory,
        List<ReportImageResponse> images,
        Instant createdAt,
        Instant updatedAt) {}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/dto/WasteReportResponse.java from your app here.
