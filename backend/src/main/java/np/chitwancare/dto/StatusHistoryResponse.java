package np.chitwancare.dto;

import java.time.Instant;
import np.chitwancare.enums.ReportStatus;

public record StatusHistoryResponse(
        ReportStatus status,
        String note,
        Instant createdAt) {}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/dto/StatusHistoryResponse.java from your app here.
