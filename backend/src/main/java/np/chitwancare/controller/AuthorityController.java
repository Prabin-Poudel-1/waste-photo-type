package np.chitwancare.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import np.chitwancare.dto.PageResponse;
import np.chitwancare.dto.WasteReportResponse;
import np.chitwancare.enums.ReportStatus;
import np.chitwancare.service.AuthorityReportService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/authority/reports")
public class AuthorityController {
    private final AuthorityReportService service;

    public AuthorityController(
            AuthorityReportService service) {
        this.service = service;
    }

    public record StatusRequest(
            @NotNull ReportStatus status,
            @Size(max = 1000) String note) {}

    public record AssignmentRequest(
            @NotNull @Positive Long departmentId,
            @Size(max = 800) String note) {}

    public record ResolveRequest(
            @Size(max = 1000) String note) {}

    @PostMapping("/{id}/assign")
    public WasteReportResponse assign(
            @PathVariable long id,
            @Valid @RequestBody
            AssignmentRequest request) {
        return service.assign(
                id,
                request.departmentId(),
                request.note());
    }

    @GetMapping
    public PageResponse<WasteReportResponse> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20")
            int size) {
        return service.list(page, size);
    }

    @PatchMapping("/{id}/status")
    public WasteReportResponse status(
            @PathVariable long id,
            @Valid @RequestBody
            StatusRequest request) {
        return service.change(
                id,
                request.status(),
                request.note(),
                null);
    }

    @PostMapping(
            value = "/{id}/resolve",
            consumes = "multipart/form-data")
    public WasteReportResponse resolve(
            @PathVariable long id,
            @Valid @RequestPart("metadata")
            ResolveRequest request,
            @RequestPart("image")
            MultipartFile image) {
        return service.change(
                id,
                ReportStatus.RESOLVED,
                request.note(),
                image);
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/controller/AuthorityController.java from your app here.
