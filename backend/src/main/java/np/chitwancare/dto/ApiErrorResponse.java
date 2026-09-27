package np.chitwancare.dto;

import java.time.Instant;
import java.util.Map;

public record ApiErrorResponse(
        Instant timestamp,
        int status,
        String error,
        String message,
        String path,
        Map<String, String> fieldErrors) {}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/dto/ApiErrorResponse.java from your app here.
