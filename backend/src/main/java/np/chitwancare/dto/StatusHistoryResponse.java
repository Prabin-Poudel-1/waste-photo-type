package np.chitwancare.dto;

import java.time.Instant;
import np.chitwancare.enums.ReportStatus;

public record StatusHistoryResponse(ReportStatus status, String note, Instant createdAt) {}
