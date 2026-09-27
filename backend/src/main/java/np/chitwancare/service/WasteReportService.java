package np.chitwancare.service;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.io.IOException;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;
import np.chitwancare.dto.CreateWasteReportRequest;
import np.chitwancare.dto.PageResponse;
import np.chitwancare.dto.WasteDetectionRequest;
import np.chitwancare.dto.WasteReportResponse;
import np.chitwancare.entity.ReportImage;
import np.chitwancare.entity.ReportStatusHistory;
import np.chitwancare.entity.WasteCategory;
import np.chitwancare.entity.WasteDetection;
import np.chitwancare.entity.WasteReport;
import np.chitwancare.enums.ImageType;
import np.chitwancare.enums.ReportStatus;
import np.chitwancare.exception.ResourceNotFoundException;
import np.chitwancare.mapper.WasteReportMapper;
import np.chitwancare.repository.WasteCategoryRepository;
import np.chitwancare.repository.WasteReportRepository;
import np.chitwancare.storage.ImageStorage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@Service
@Validated
public class WasteReportService {
    private static final Logger log =
            LoggerFactory.getLogger(
                    WasteReportService.class);

    private final WasteReportRepository reports;
    private final WasteCategoryRepository categories;
    private final WasteReportMapper mapper;
    private final TouristSpotService touristSpots;
    private final ImageStorage storage;
    private final ReportAccessService access;

    public WasteReportService(
            WasteReportRepository reports,
            WasteCategoryRepository categories,
            WasteReportMapper mapper,
            TouristSpotService touristSpots,
            ImageStorage storage,
            ReportAccessService access) {
        this.reports = reports;
        this.categories = categories;
        this.mapper = mapper;
        this.touristSpots = touristSpots;
        this.storage = storage;
        this.access = access;
    }

    @Transactional
    public WasteReportResponse create(
            @NotNull @Valid
            CreateWasteReportRequest request) {
        return mapper.toResponse(
                reports.saveAndFlush(build(request)));
    }

    @Transactional
    public WasteReportResponse createWithImage(
            @NotNull @Valid
            CreateWasteReportRequest request,
            MultipartFile file) {
        var report = build(request);

        try (var input = file.getInputStream()) {
            var stored =
                    storage.store(
                            input,
                            file.getOriginalFilename(),
                            file.getContentType(),
                            file.getSize());

            // Runs after the outer transaction completes, including failures during commit.
            TransactionSynchronizationManager
                    .registerSynchronization(
                            new TransactionSynchronization() {
                                @Override
                                public void afterCompletion(
                                        int status) {
                                    if (status
                                            != STATUS_COMMITTED) {
                                        try {
                                            storage.delete(
                                                    stored.storageKey());
                                        } catch (
                                                IOException exception) {
                                            log.error(
                                                    "Could not clean up rolled-back report image");
                                        }
                                    }
                                }
                            });

            var image = new ReportImage();
            image.setImageType(ImageType.ORIGINAL);
            image.setStorageKey(
                    stored.storageKey());
            image.setContentType(
                    stored.contentType());

            String name =
                    Objects.requireNonNullElse(
                            file.getOriginalFilename(),
                            "photo");

            name = name.replace('\\', '/');

            name =
                    name
                            .substring(
                                    name.lastIndexOf('/') + 1)
                            .replaceAll(
                                    "[^a-zA-Z0-9._ -]",
                                    "_");

            if (name.isBlank()) {
                name = "photo";
            }

            image.setOriginalFilename(
                    name.substring(
                            0,
                            Math.min(255, name.length())));

            report.addImage(image);

            return mapper.toResponse(
                    reports.saveAndFlush(report));
        } catch (IOException exception) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Image could not be stored. Please retry.");
        }
    }

    private WasteReport build(
            CreateWasteReportRequest request) {
        var ids =
                request
                        .detections()
                        .stream()
                        .map(
                                WasteDetectionRequest
                                        ::categoryId)
                        .collect(Collectors.toSet());

        var catalog =
                categories
                        .findByIdInAndActiveTrue(ids)
                        .stream()
                        .collect(
                                Collectors.toMap(
                                        WasteCategory::getId,
                                        Function.identity()));

        if (catalog.size() != ids.size()) {
            throw new ResourceNotFoundException(
                    "One or more waste categories do not exist or are inactive.");
        }

        var report = new WasteReport();

        if (request.touristSpotId() != null) {
            report.setTouristSpot(
                    touristSpots.requireActive(
                            request.touristSpotId()));
        }

        report.setDescription(
                trim(request.description()));
        report.setAddress(
                trim(request.address()));
        report.setLatitude(
                request.latitude());
        report.setLongitude(
                request.longitude());
        report.setSeverity(
                request.severity());
        report.setCurrentStatus(
                ReportStatus.SUBMITTED);
        report.setReporter(
                access.currentUser());

        for (var detection :
                request.detections()) {
            var item = new WasteDetection();

            item.setWasteCategory(
                    catalog.get(
                            detection.categoryId()));
            item.setDetectedLabel(
                    detection.label().trim());
            item.setConfidence(
                    detection.confidence());

            report.addDetection(item);
        }

        var history =
                new ReportStatusHistory();
        history.setStatus(
                ReportStatus.SUBMITTED);
        report.addHistory(history);

        return report;
    }

    @Transactional(readOnly = true)
    public WasteReportResponse get(
            @Positive long id) {
        var report =
                reports
                        .findById(id)
                        .orElseThrow(
                                () ->
                                        new ResourceNotFoundException(
                                                "Report not found."));

        access.requireReadable(report);

        return mapper.toResponse(report);
    }

    @Transactional(readOnly = true)
    public PageResponse<WasteReportResponse> mine(
            @Min(0) int page,
            @Min(1) @Max(100) int size) {
        var result =
                reports.findByReporterId(
                        access.currentUser().getId(),
                        PageRequest.of(
                                page,
                                size,
                                Sort.by(
                                        Sort.Order.desc("createdAt"),
                                        Sort.Order.desc("id"))));

        return new PageResponse<>(
                result
                        .getContent()
                        .stream()
                        .map(mapper::toResponse)
                        .toList(),
                page,
                size,
                result.getTotalElements(),
                result.getTotalPages());
    }

    @Transactional(readOnly = true)
    public PageResponse<WasteReportResponse> list(
            @Min(0) int page,
            @Min(1) @Max(100) int size) {
        var result =
                reports.findAll(
                        PageRequest.of(
                                page,
                                size,
                                Sort.by(
                                        Sort.Order.desc("createdAt"),
                                        Sort.Order.desc("id"))));

        return new PageResponse<>(
                result
                        .getContent()
                        .stream()
                        .map(mapper::toResponse)
                        .toList(),
                page,
                size,
                result.getTotalElements(),
                result.getTotalPages());
    }

    private String trim(String value) {
        return value == null
                ? null
                : value.trim();
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/service/WasteReportService.java from your app here.
