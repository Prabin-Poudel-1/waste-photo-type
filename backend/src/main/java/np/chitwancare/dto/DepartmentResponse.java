package np.chitwancare.dto;

public record DepartmentResponse(
    Long id, String name, String description, String contactEmail, String contactPhone) {}
