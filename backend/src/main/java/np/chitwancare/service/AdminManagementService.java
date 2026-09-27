package np.chitwancare.service;

import np.chitwancare.dto.AdminManagementDtos.*;
import java.util.List;
import np.chitwancare.entity.*;
import np.chitwancare.enums.Role;
import np.chitwancare.exception.ResourceNotFoundException;
import np.chitwancare.repository.*;
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

  public AdminManagementService(DepartmentRepository departments, TouristSpotRepository spots, ReportAccessService access) {
    this.departments = departments;
    this.spots = spots;
    this.access = access;
  }

  private void admin() {
    if (access.currentUser().getRole() != Role.ADMIN)
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Admin access required.");
  }
  private void unique(boolean exists) {
    if (exists) throw new ResponseStatusException(HttpStatus.CONFLICT, "A record with this name already exists, including inactive records.");
  }
  private DepartmentView view(Department d) {
    return new DepartmentView(d.getId(), d.getName(), d.getDescription(), d.isActive());
  }
  private SpotView view(TouristSpot s) {
    return new SpotView(s.getId(), s.getName(), s.getDescription(), s.getLatitude(), s.getLongitude(), s.getRadiusMeters(), s.getAddress(), s.isActive());
  }
  public List<DepartmentView> departments() {
    admin();
    return departments.findAll(Sort.by("name", "id")).stream().map(this::view).toList();
  }
  public List<SpotView> spots() {
    admin();
    return spots.findAll(Sort.by("name", "id")).stream().map(this::view).toList();
  }
  @Transactional
  public DepartmentView saveDepartment(Long id, DepartmentInput input) {
    admin();
    var d = id == null ? new Department() : departments.findById(id)
        .orElseThrow(() -> new ResourceNotFoundException("Department not found."));
    unique(departments.nameExists(input.name().trim(), id));
    d.setName(input.name().trim());
    d.setDescription(input.description());
    d.setActive(input.active());
    // Existing contact fields, user links and assignment history are untouched.
    return view(departments.saveAndFlush(d));
  }
  @Transactional
  public SpotView saveSpot(Long id, SpotInput input) {
    admin();
    var s = id == null ? new TouristSpot() : spots.findById(id)
        .orElseThrow(() -> new ResourceNotFoundException("Tourist spot not found."));
    unique(spots.nameExists(input.name().trim(), id));
    s.setName(input.name().trim());
    s.setDescription(input.description());
    s.setLatitude(input.latitude());
    s.setLongitude(input.longitude());
    s.setRadiusMeters(input.radiusMeters());
    s.setAddress(input.address());
    s.setActive(input.active());
    return view(spots.saveAndFlush(s));
  }
}
