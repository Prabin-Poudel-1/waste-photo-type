package np.chitwancare.analysis;

import java.io.IOException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/analyses")
public class AnalysisController {
    private final AnalysisService service;

    public AnalysisController(
            AnalysisService service) {
        this.service = service;
    }

    @PostMapping(consumes = "multipart/form-data")
    public ResponseEntity<DetectionResult> analyze(
            @RequestPart("image")
            MultipartFile image,
            @RequestParam(defaultValue = "multiple")
            String scenario)
            throws IOException {
        return ResponseEntity
                .accepted()
                .body(
                        service.analyze(
                                image,
                                scenario));
    }

    @GetMapping("/{id}")
    public DetectionResult get(
            @PathVariable String id) {
        return service.get(id);
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/analysis/AnalysisController.java from your app here.
