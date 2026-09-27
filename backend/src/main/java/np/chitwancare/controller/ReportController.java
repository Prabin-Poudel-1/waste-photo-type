package np.chitwancare.controller;

import jakarta.validation.Valid;
import java.net.URI;
import np.chitwancare.dto.*;
import np.chitwancare.service.WasteReportService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {
  private final WasteReportService service;
  private final np.chitwancare.service.ReportImageService images;

  public ReportController(
      WasteReportService service, np.chitwancare.service.ReportImageService images) {
    this.service = service;
    this.images = images;
  }

  @PostMapping(consumes = "multipart/form-data")
  public ResponseEntity<WasteReportResponse> upload(
      @Valid @RequestPart("metadata") CreateWasteReportRequest request,
      @RequestPart("image") org.springframework.web.multipart.MultipartFile image) {
    var report = service.createWithImage(request, image);
    return ResponseEntity.created(URI.create("/api/v1/reports/" + report.id())).body(report);
  }

  @GetMapping("/{reportId}/images/{imageId}")
  public ResponseEntity<byte[]> image(@PathVariable long reportId, @PathVariable long imageId) {
    var download = images.get(reportId, imageId);
    return ResponseEntity.ok()
        .header("X-Content-Type-Options", "nosniff")
        .header("Content-Disposition", "inline")
        .contentType(org.springframework.http.MediaType.parseMediaType(download.contentType()))
        .body(download.bytes());
  }

  @PostMapping(consumes = "application/json")
  public ResponseEntity<WasteReportResponse> create(
      @Valid @RequestBody CreateWasteReportRequest request) {
    var report = service.create(request);
    return ResponseEntity.created(URI.create("/api/v1/reports/" + report.id())).body(report);
  }

  @GetMapping
  public PageResponse<WasteReportResponse> list(
      @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
    return service.list(page, size);
  }

  @GetMapping("/{id}")
  public WasteReportResponse get(@PathVariable long id) {
    return service.get(id);
  }

  @GetMapping("/mine")
  public PageResponse<WasteReportResponse> mine(
      @RequestParam(defaultValue="0") int page, @RequestParam(defaultValue="20") int size) {
    return service.mine(page,size);
  }
}
