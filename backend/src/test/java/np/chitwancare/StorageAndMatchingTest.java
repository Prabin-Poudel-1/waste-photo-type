package np.chitwancare;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.math.BigDecimal;
import java.nio.file.Path;
import java.util.List;
import np.chitwancare.entity.TouristSpot;
import np.chitwancare.repository.TouristSpotRepository;
import np.chitwancare.service.TouristSpotService;
import np.chitwancare.storage.LocalImageStorage;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class StorageAndMatchingTest {
  @TempDir Path temporary;

  @Test
  void opaqueKeysRejectTraversalAndAbsolutePaths() {
    var storage = new LocalImageStorage(temporary.toString());
    for (String key : List.of("../secrets", "/etc/passwd", "photo.png", "..\\secrets")) {
      assertThrows(java.io.IOException.class, () -> storage.open(key));
      assertThrows(java.io.IOException.class, () -> storage.delete(key));
    }
  }

  @Test
  void distanceIsGeographicAndHandlesDateline() {
    assertEquals(0, TouristSpotService.distance(0, 0, 0, 0), .001);
    assertEquals(111195, TouristSpotService.distance(0, 0, 0, 1), 2);
    assertEquals(222390, TouristSpotService.distance(0, 179, 0, -179), 3);
  }

  @Test
  void matchingRequiresRadiusAndChoosesClosestContainingSpot() {
    var repo = mock(TouristSpotRepository.class);
    var a = new TouristSpot();
    a.setName("Development near");
    a.setLatitude(BigDecimal.ZERO);
    a.setLongitude(BigDecimal.ZERO);
    a.setRadiusMeters(100);
    var b = new TouristSpot();
    b.setName("Development far");
    b.setLatitude(BigDecimal.ZERO);
    b.setLongitude(new BigDecimal("0.001"));
    b.setRadiusMeters(1000);
    when(repo.findByActiveTrueOrderByNameAscIdAsc()).thenReturn(List.of(b, a));
    var service = new TouristSpotService(repo);
    assertEquals(a.getName(), service.nearest(0, .0001).name());
    assertEquals(b.getName(), service.nearest(0, .005).name());
    assertNull(service.nearest(10, 10));
  }
}
