package np.chitwancare.repository;

import java.util.List;
import java.util.Optional;
import np.chitwancare.entity.TouristSpot;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TouristSpotRepository extends JpaRepository<TouristSpot, Long> {
  List<TouristSpot> findByActiveTrueOrderByNameAscIdAsc();

  Optional<TouristSpot> findByIdAndActiveTrue(Long id);
  @org.springframework.data.jpa.repository.Query("select count(e) > 0 from TouristSpot e where lower(trim(e.name)) = lower(:name) and (:id is null or e.id <> :id)")
  boolean nameExists(@org.springframework.data.repository.query.Param("name") String name,
      @org.springframework.data.repository.query.Param("id") Long id);
}
