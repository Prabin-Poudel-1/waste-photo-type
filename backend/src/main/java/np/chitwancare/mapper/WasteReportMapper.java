package np.chitwancare.mapper;

import np.chitwancare.dto.*;
import np.chitwancare.entity.WasteReport;
import org.springframework.stereotype.Component;

@Component
public class WasteReportMapper {
  public WasteReportResponse toResponse(WasteReport r) {
    return new WasteReportResponse(
        r.getId(),
        r.getDescription(),
        r.getLatitude(),
        r.getLongitude(),
        r.getAddress(),
        r.getSeverity(),
        r.getCurrentStatus(),
        r.getTouristSpot() == null
            ? null
            : new TouristSpotSummary(r.getTouristSpot().getId(), r.getTouristSpot().getName()),
        r.getDetections().stream()
            .map(
                d ->
                    new WasteDetectionResponse(
                        d.getId(),
                        d.getWasteCategory().getId(),
                        d.getWasteCategory().getName(),
                        d.getDetectedLabel(),
                        d.getConfidence()))
            .toList(),
        r.getStatusHistory().stream()
            .map(h -> new StatusHistoryResponse(h.getStatus(), h.getNote(), h.getCreatedAt()))
            .toList(),
        r.getImages().stream()
            .map(
                i ->
                    new ReportImageResponse(
                        i.getId(),
                        i.getImageType(),
                        i.getOriginalFilename(),
                        i.getContentType(),
                        i.getCreatedAt(),
                        "/api/v1/reports/" + r.getId() + "/images/" + i.getId()))
            .toList(),
        r.getCreatedAt(),
        r.getUpdatedAt());
  }
}
