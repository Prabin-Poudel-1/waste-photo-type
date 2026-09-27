package np.chitwancare.service;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import np.chitwancare.entity.Department;
import np.chitwancare.entity.TouristSpot;
import np.chitwancare.enums.Role;
import np.chitwancare.exception.ResourceNotFoundException;
import np.chitwancare.repository.DepartmentRepository;
import np.chitwancare.repository.TouristSpotRepository;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@Transactional(readOnly = true)
public class AdminManagementService {
    private final DepartmentRepository departments;
    private final TouristSpotRepository spots;
    private final ReportAccessService access;

    public AdminManagementService(
            DepartmentRepository departments,
            TouristSpotRepository spots,
            ReportAccessService access) {
        this.departments = departments;
        this.spots = spots;
        this.access = access;
    }

    public record DepartmentInput(
            @NotBlank @Size(max = 150) String name,
            @Size(max = 1000) String description,
            @NotNull Boolean active) {}

    public record SpotInput(
            @NotBlank @Size(max = 150) String name,
            @Size(max = 2000) String description,
            @NotNull
            @DecimalMin("-90")
            @DecimalMax("90")
            @Digits(integer = 3, fraction = 6)
            BigDecimal latitude,
            @NotNull
            @DecimalMin("-180")
            @DecimalMax("180")
            @Digits(integer = 3, fraction = 6)
            BigDecimal longitude,
            @NotNull @Positive Integer radiusMeters,
            @Size(max = 500) String address,
            @NotNull Boolean active) {}

    public record DepartmentView(
            Long id,
            String name,
            String description,
            boolean active) {}

    public record SpotView(
            Long id,
            String name,
            String description,
            BigDecimal latitude,
            BigDecimal longitude,
            Integer radiusMeters,
            String address,
            boolean active) {}

    private void admin() {
        if (access.currentUser().getRole() != Role.ADMIN) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Admin access required.");
        }
    }

    private void unique(boolean exists) {
        if (exists) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "A record with this name already exists, including inactive records.");
        }
    }

    private DepartmentView view(Department department) {
        return new DepartmentView(
                department.getId(),
                department.getName(),
                department.getDescription(),
                department.isActive());
    }

    private SpotView view(TouristSpot spot) {
        return new SpotView(
                spot.getId(),
                spot.getName(),
                spot.getDescription(),
                spot.getLatitude(),
                spot.getLongitude(),
                spot.getRadiusMeters(),
                spot.getAddress(),
                spot.isActive());
    }

    public List<DepartmentView> departments() {
        admin();

        return departments
                .findAll(Sort.by("name", "id"))
                .stream()
                .map(this::view)
                .toList();
    }

    public List<SpotView> spots() {
        admin();

        return spots
                .findAll(Sort.by("name", "id"))
                .stream()
                .map(this::view)
                .toList();
    }

    @Transactional
    public DepartmentView saveDepartment(
            Long id,
            DepartmentInput input) {
        admin();

        var department =
                id == null
                        ? new Department()
                        : departments
                        .findById(id)
                        .orElseThrow(
                                () ->
                                new ResourceNotFoundException(
                                        "Department not found."));

        unique(
                departments.nameExists(
                        input.name().trim(),
                        id));

        department.setName(input.name().trim());
        department.setDescription(input.description());
        department.setActive(input.active());

        // Existing contact fields, user links and assignment history are untouched.
        return view(
                departments.saveAndFlush(department));
    }

    @Transactional
    public SpotView saveSpot(
            Long id,
            SpotInput input) {
        admin();

        var spot =
                id == null
                        ? new TouristSpot()
                        : spots
                        .findById(id)
                        .orElseThrow(
                                () ->
                                new ResourceNotFoundException(
                                        "Tourist spot not found."));

        unique(
                spots.nameExists(
                        input.name().trim(),
                        id));

        spot.setName(input.name().trim());
        spot.setDescription(input.description());
        spot.setLatitude(input.latitude());
        spot.setLongitude(input.longitude());
        spot.setRadiusMeters(input.radiusMeters());
        spot.setAddress(input.address());
        spot.setActive(input.active());

        return view(spots.saveAndFlush(spot));
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/service/AdminManagementService.java from your app here.
