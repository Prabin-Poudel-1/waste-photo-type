package np.chitwancare.repository;

import np.chitwancare.entity.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {
  java.util.Optional<AppUser> findByEmail(String email);
}
