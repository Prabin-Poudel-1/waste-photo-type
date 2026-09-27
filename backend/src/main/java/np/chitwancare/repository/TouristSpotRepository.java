package np.chitwancare.repository;

import java.util.List;
import java.util.Optional;
import np.chitwancare.entity.TouristSpot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TouristSpotRepository
        extends JpaRepository<TouristSpot, Long> {
    List<TouristSpot> findByActiveTrueOrderByNameAscIdAsc();

    Optional<TouristSpot> findByIdAndActiveTrue(Long id);

    @Query(
            "select count(e) > 0 from TouristSpot e "
                    + "where lower(trim(e.name)) = lower(:name) "
                    + "and (:id is null or e.id <> :id)")
    boolean nameExists(
            @Param("name") String name,
            @Param("id") Long id);
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/repository/TouristSpotRepository.java from your app here.
