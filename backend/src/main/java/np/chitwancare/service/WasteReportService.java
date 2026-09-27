package np.chitwancare.service;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;
import np.chitwancare.dto.*;
import np.chitwancare.entity.*;
import np.chitwancare.enums.ReportStatus;
import np.chitwancare.exception.ResourceNotFoundException;
import np.chitwancare.mapper.WasteReportMapper;
import np.chitwancare.repository.*;
import org.slf4j.*;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

@Service
@Validated
public class WasteReportService {
  private static final Logger log = LoggerFactory.getLogger(WasteReportService.class);
  private final WasteReportRepository reports;
  private final WasteCategoryRepository categories;
  private final WasteReportMapper mapper;
  private final TouristSpotService touristSpots;
  private final np.chitwancare.storage.ImageStorage storage;
  private final ReportAccessService access;

  public WasteReportService(
      WasteReportRepository reports,
      WasteCategoryRepository categories,
      WasteReportMapper mapper,
      TouristSpotService touristSpots,
      np.chitwancare.storage.ImageStorage storage, ReportAccessService access) {
    this.reports = reports;
    this.categories = categories;
    this.mapper = mapper;
    this.touristSpots = touristSpots;
    this.storage = storage;
    this.access = access;
  }

  @Transactional
  public WasteReportResponse create(@NotNull @Valid CreateWasteReportRequest request) {
    return mapper.toResponse(reports.saveAndFlush(build(request)));
  }

  @Transactional
  public WasteReportResponse createWithImage(
      @NotNull @Valid CreateWasteReportRequest request,
      org.springframework.web.multipart.MultipartFile file) {
    var report = build(request);
    try (var input = file.getInputStream()) {
      var stored =
          storage.store(input, file.getOriginalFilename(), file.getContentType(), file.getSize());
      // Runs after the outer transaction completes, including failures during commit.
      org.springframework.transaction.support.TransactionSynchronizationManager
          .registerSynchronization(
              new org.springframework.transaction.support.TransactionSynchronization() {
                @Override
                public void afterCompletion(int status) {
                  if (status != STATUS_COMMITTED) {
                    try {
                      storage.delete(stored.storageKey());
                    } catch (java.io.IOException ex) {
                      log.error("Could not clean up rolled-back report image");
                    }
                  }
                }
              });
      var image = new ReportImage();
      image.setImageType(np.chitwancare.enums.ImageType.ORIGINAL);
      image.setStorageKey(stored.storageKey());
      image.setContentType(stored.contentType());
      String name = Objects.requireNonNullElse(file.getOriginalFilename(), "photo");
      name = name.replace('\\', '/');
      name = name.substring(name.lastIndexOf('/') + 1).replaceAll("[^a-zA-Z0-9._ -]", "_");
      if (name.isBlank()) name = "photo";
      image.setOriginalFilename(name.substring(0, Math.min(255, name.length())));
      report.addImage(image);
      return mapper.toResponse(reports.saveAndFlush(report));
    } catch (java.io.IOException ex) {
      throw new org.springframework.web.server.ResponseStatusException(
          org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE,
          "Image could not be stored. Please retry.");
    }
  }

  private WasteReport build(CreateWasteReportRequest request) {
    var ids =
        request.detections().stream()
            .map(WasteDetectionRequest::categoryId)
            .collect(Collectors.toSet());
    var catalog =
        categories.findByIdInAndActiveTrue(ids).stream()
            .collect(Collectors.toMap(WasteCategory::getId, Function.identity()));
    if (catalog.size() != ids.size())
      throw new ResourceNotFoundException(
          "One or more waste categories do not exist or are inactive.");
    var report = new WasteReport();
    if (request.touristSpotId() != null)
      report.setTouristSpot(touristSpots.requireActive(request.touristSpotId()));
    report.setDescription(trim(request.description()));
    report.setAddress(trim(request.address()));
    report.setLatitude(request.latitude());
    report.setLongitude(request.longitude());
    report.setSeverity(request.severity());
    report.setCurrentStatus(ReportStatus.SUBMITTED);
    report.setReporter(access.currentUser());
    for (var detection : request.detections()) {
      var item = new WasteDetection();
      item.setWasteCategory(catalog.get(detection.categoryId()));
      item.setDetectedLabel(detection.label().trim());
      item.setConfidence(detection.confidence());
      report.addDetection(item);
    }
    var history = new ReportStatusHistory();
    history.setStatus(ReportStatus.SUBMITTED);
    report.addHistory(history);
    return report;
  }

  @Transactional(readOnly = true)
  public WasteReportResponse get(@Positive long id) {
    var report=reports.findById(id).orElseThrow(() -> new ResourceNotFoundException("Report not found."));
    access.requireReadable(report);
    return mapper.toResponse(report);
  }

  @Transactional(readOnly=true)
  public PageResponse<WasteReportResponse> mine(@Min(0) int page, @Min(1) @Max(100) int size) {
    var result=reports.findByReporterId(access.currentUser().getId(),
        PageRequest.of(page,size,Sort.by(Sort.Order.desc("createdAt"),Sort.Order.desc("id"))));
    return new PageResponse<>(result.getContent().stream().map(mapper::toResponse).toList(),
        page,size,result.getTotalElements(),result.getTotalPages());
  }

  @Transactional(readOnly = true)
  public PageResponse<WasteReportResponse> list(@Min(0) int page, @Min(1) @Max(100) int size) {
    var result =
        reports.findAll(
            PageRequest.of(
                page, size, Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"))));
    return new PageResponse<>(
        result.getContent().stream().map(mapper::toResponse).toList(),
        page,
        size,
        result.getTotalElements(),
        result.getTotalPages());
  }

  private String trim(String value) {
    return value == null ? null : value.trim();
  }
}
