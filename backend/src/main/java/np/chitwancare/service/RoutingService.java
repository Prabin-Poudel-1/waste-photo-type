package np.chitwancare.service;

import java.util.Optional;
import java.util.Set;

// Future routing implementation will evaluate database rules. No automatic routing in Phase 2.
public interface RoutingService {
  Optional<Long> suggestDepartment(Set<Long> categoryIds, String areaIdentifier);
}
