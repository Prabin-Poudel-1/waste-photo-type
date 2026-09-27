package np.chitwancare.service;

import np.chitwancare.entity.AppUser;
import np.chitwancare.entity.WasteReport;
import np.chitwancare.enums.Role;
import np.chitwancare.exception.ResourceNotFoundException;
import np.chitwancare.repository.AppUserRepository;
import np.chitwancare.repository.ReportAssignmentRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ReportAccessService {
    private final AppUserRepository users;
    private final ReportAssignmentRepository assignments;

    public ReportAccessService(
            AppUserRepository users,
            ReportAssignmentRepository assignments) {
        this.users = users;
        this.assignments = assignments;
    }

    public Long departmentId(AppUser user) {
        if (user.getDepartment() == null
                || !user.getDepartment().isActive()) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Your account needs an active department. Contact the administrator.");
        }

        return user.getDepartment().getId();
    }

    public void requireAssigned(
            AppUser user,
            WasteReport report) {
        if (!assignments
                .existsByReportIdAndDepartmentIdAndActiveTrue(
                        report.getId(),
                        departmentId(user))) {
            throw new ResourceNotFoundException(
                    "Report not found.");
        }
    }

    public AppUser currentUser() {
        var authentication =
                SecurityContextHolder
                        .getContext()
                        .getAuthentication();

        if (authentication == null
                || !(authentication.getPrincipal()
                instanceof Jwt jwt)) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Please log in.");
        }

        try {
            return users
                    .findById(
                            Long.parseLong(jwt.getSubject()))
                    .filter(AppUser::isActive)
                    .orElseThrow(
                            () ->
                                    new ResponseStatusException(
                                            HttpStatus.UNAUTHORIZED,
                                            "Please log in."));
        } catch (NumberFormatException exception) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Invalid token.");
        }
    }

    public AppUser requireAuthority() {
        var user = currentUser();

        if (user.getRole() != Role.ADMIN
                && user.getRole() != Role.DEPARTMENT) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Authority access required.");
        }

        return user;
    }

    public void requireReadable(
            WasteReport report) {
        var user = currentUser();

        if (user.getRole() == Role.DEPARTMENT) {
            requireAssigned(user, report);
            return;
        }

        if (user.getRole() != Role.ADMIN
                && (report.getReporter() == null
                || !report
                .getReporter()
                .getId()
                .equals(user.getId()))) {
            throw new ResourceNotFoundException(
                    "Report not found.");
        }
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/service/ReportAccessService.java from your app here.
