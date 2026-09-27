package np.chitwancare.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class HealthService {
    private final JdbcTemplate jdbc;

    public HealthService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public boolean databaseAvailable() {
        try {
            return Integer.valueOf(1)
                    .equals(
                            jdbc.queryForObject(
                                    "SELECT 1",
                                    Integer.class));
        } catch (RuntimeException exception) {
            return false;
        }
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/service/HealthService.java from your app here.
