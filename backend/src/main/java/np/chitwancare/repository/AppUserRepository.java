package np.chitwancare.repository;

import java.util.Optional;
import np.chitwancare.entity.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppUserRepository
        extends JpaRepository<AppUser, Long> {
    Optional<AppUser> findByEmail(String email);
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/repository/AppUserRepository.java from your app here.
