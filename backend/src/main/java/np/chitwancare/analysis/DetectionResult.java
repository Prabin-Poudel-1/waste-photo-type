package np.chitwancare.analysis;

import java.time.Instant;
import java.util.List;

public record DetectionResult(
        String id,
        String status,
        int schemaVersion,
        String modelVersion,
        boolean isMock,
        boolean wasteDetected,
        List<Detection> detections,
        Instant analyzedAt) {
    public record Detection(
            String categoryCode,
            String label,
            double confidence) {}
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/analysis/DetectionResult.java from your app here.
