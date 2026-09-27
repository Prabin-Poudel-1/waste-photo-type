package np.chitwancare.mapper;

import np.chitwancare.dto.ReportImageResponse;
import np.chitwancare.dto.StatusHistoryResponse;
import np.chitwancare.dto.TouristSpotSummary;
import np.chitwancare.dto.WasteDetectionResponse;
import np.chitwancare.dto.WasteReportResponse;
import np.chitwancare.entity.WasteReport;
import org.springframework.stereotype.Component;

@Component
public class WasteReportMapper {
    public WasteReportResponse toResponse(
            WasteReport report) {
        return new WasteReportResponse(
                report.getId(),
                report.getDescription(),
                report.getLatitude(),
                report.getLongitude(),
                report.getAddress(),
                report.getSeverity(),
                report.getCurrentStatus(),
                report.getTouristSpot() == null
                        ? null
                        : new TouristSpotSummary(
                        report
                                .getTouristSpot()
                                .getId(),
                        report
                                .getTouristSpot()
                                .getName()),
                report
                        .getDetections()
                        .stream()
                        .map(
                                detection ->
                                        new WasteDetectionResponse(
                                                detection.getId(),
                                                detection
                                                        .getWasteCategory()
                                                        .getId(),
                                                detection
                                                        .getWasteCategory()
                                                        .getName(),
                                                detection
                                                        .getDetectedLabel(),
                                                detection
                                                        .getConfidence()))
                        .toList(),
                report
                        .getStatusHistory()
                        .stream()
                        .map(
                                history ->
                                        new StatusHistoryResponse(
                                                history.getStatus(),
                                                history.getNote(),
                                                history.getCreatedAt()))
                        .toList(),
                report
                        .getImages()
                        .stream()
                        .map(
                                image ->
                                        new ReportImageResponse(
                                                image.getId(),
                                                image.getImageType(),
                                                image.getOriginalFilename(),
                                                image.getContentType(),
                                                image.getCreatedAt(),
                                                "/api/v1/reports/"
                                                        + report.getId()
                                                        + "/images/"
                                                        + image.getId()))
                        .toList(),
                report.getCreatedAt(),
                report.getUpdatedAt());
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/mapper/WasteReportMapper.java from your app here.
