package np.chitwancare.dto;

import java.util.List;

public record PageResponse<T>(
        List<T> content,
        int page,
        int size,
        long totalElements,
        int totalPages) {}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/dto/PageResponse.java from your app here.
