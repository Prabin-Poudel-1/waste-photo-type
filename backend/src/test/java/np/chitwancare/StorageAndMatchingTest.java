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
        var storage =
                new LocalImageStorage(
                        temporary.toString());

        for (String key :
                List.of(
                        "../secrets",
                        "/etc/passwd",
                        "photo.png",
                        "..\\secrets")) {
            assertThrows(
                    java.io.IOException.class,
                    () -> storage.open(key));

            assertThrows(
                    java.io.IOException.class,
                    () -> storage.delete(key));
        }
    }

    @Test
    void distanceIsGeographicAndHandlesDateline() {
        assertEquals(
                0,
                TouristSpotService.distance(
                        0, 0, 0, 0),
                .001);

        assertEquals(
                111195,
                TouristSpotService.distance(
                        0, 0, 0, 1),
                2);

        assertEquals(
                222390,
                TouristSpotService.distance(
                        0, 179, 0, -179),
                3);
    }

    @Test
    void matchingRequiresRadiusAndChoosesClosestContainingSpot() {
        var repository =
                mock(TouristSpotRepository.class);

        var near = new TouristSpot();
        near.setName("Development near");
        near.setLatitude(BigDecimal.ZERO);
        near.setLongitude(BigDecimal.ZERO);
        near.setRadiusMeters(100);

        var far = new TouristSpot();
        far.setName("Development far");
        far.setLatitude(BigDecimal.ZERO);
        far.setLongitude(
                new BigDecimal("0.001"));
        far.setRadiusMeters(1000);

        when(
                repository
                        .findByActiveTrueOrderByNameAscIdAsc())
                .thenReturn(List.of(far, near));

        var service =
                new TouristSpotService(repository);

        assertEquals(
                near.getName(),
                service.nearest(0, .0001).name());

        assertEquals(
                far.getName(),
                service.nearest(0, .005).name());

        assertNull(
                service.nearest(10, 10));
    }
}// Placeholder: paste the contents of backend/src/test/java/np/chitwancare/StorageAndMatchingTest.java from your app here.
