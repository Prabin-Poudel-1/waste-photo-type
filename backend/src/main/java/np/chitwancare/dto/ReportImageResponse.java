package np.chitwancare.dto;

import java.time.Instant;
import np.chitwancare.enums.ImageType;

public record ReportImageResponse(
    Long id,
    ImageType imageType,
    String originalFilename,
    String contentType,
    Instant createdAt,
    String url) {}
