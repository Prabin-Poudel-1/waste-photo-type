package np.chitwancare.controller;

import jakarta.validation.Valid;
import java.net.URI;
import np.chitwancare.dto.CreateWasteReportRequest;
import np.chitwancare.dto.PageResponse;
import np.chitwancare.dto.WasteReportResponse;
import np.chitwancare.service.ReportImageService;
import np.chitwancare.service.WasteReportService;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {
    private final WasteReportService service;
    private final ReportImageService images;

    public ReportController(
            WasteReportService service,
            ReportImageService images) {
        this.service = service;
        this.images = images;
    }

    @PostMapping(consumes = "multipart/form-data")
    public ResponseEntity<WasteReportResponse> upload(
            @Valid @RequestPart("metadata")
            CreateWasteReportRequest request,
            @RequestPart("image")
            MultipartFile image) {
        var report =
                service.createWithImage(request, image);

        return ResponseEntity
                .created(
                        URI.create(
                                "/api/v1/reports/"
                                        + report.id()))
                .body(report);
    }

    @GetMapping("/{reportId}/images/{imageId}")
    public ResponseEntity<byte[]> image(
            @PathVariable long reportId,
            @PathVariable long imageId) {
        var download =
                images.get(reportId, imageId);

        return ResponseEntity.ok()
                .header(
                        "X-Content-Type-Options",
                        "nosniff")
                .header(
                        "Content-Disposition",
                        "inline")
                .contentType(
                        MediaType.parseMediaType(
                                download.contentType()))
                .body(download.bytes());
    }

    @PostMapping(consumes = "application/json")
    public ResponseEntity<WasteReportResponse> create(
            @Valid @RequestBody
            CreateWasteReportRequest request) {
        var report = service.create(request);

        return ResponseEntity
                .created(
                        URI.create(
                                "/api/v1/reports/"
                                        + report.id()))
                .body(report);
    }

    @GetMapping
    public PageResponse<WasteReportResponse> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20")
            int size) {
        return service.list(page, size);
    }

    @GetMapping("/{id}")
    public WasteReportResponse get(
            @PathVariable long id) {
        return service.get(id);
    }

    @GetMapping("/mine")
    public PageResponse<WasteReportResponse> mine(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20")
            int size) {
        return service.mine(page, size);
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/controller/ReportController.java from your app here.
