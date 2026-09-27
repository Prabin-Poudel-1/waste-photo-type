package np.chitwancare.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import np.chitwancare.enums.*;

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
    Instant updatedAt) {}
