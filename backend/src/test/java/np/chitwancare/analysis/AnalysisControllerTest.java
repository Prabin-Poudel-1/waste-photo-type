package np.chitwancare.analysis;

import static org.junit.jupiter.api.Assertions.*;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.server.ResponseStatusException;

class AnalysisControllerTest {
  private MockMultipartFile image() throws Exception {
    var out = new ByteArrayOutputStream();
    ImageIO.write(new BufferedImage(10, 10, BufferedImage.TYPE_INT_RGB), "png", out);
    return new MockMultipartFile("image", "scene.png", "image/png", out.toByteArray());
  }

  @Test
  void uploadAndRetrieveMultipleDetections() throws Exception {
    var controller = new AnalysisController(new AnalysisService(new MockWasteDetectionService()));
    var response = controller.analyze(image(), "multiple");
    var result = response.getBody();
    assertEquals(202, response.getStatusCode().value());
    assertTrue(result.isMock());
    assertTrue(result.wasteDetected());
    assertEquals(3, result.detections().size());
    assertEquals(.94, result.detections().getFirst().confidence());
    assertEquals(result, controller.get(result.id()));
  }

  @Test
  void noWasteAndLowConfidence() throws Exception {
    var controller = new AnalysisController(new AnalysisService(new MockWasteDetectionService()));
    assertFalse(controller.analyze(image(), "none").getBody().wasteDetected());
    assertTrue(
        controller.analyze(image(), "low").getBody().detections().getFirst().confidence() < .6);
  }

  @Test
  void invalidBytesRejectedEvenWithImageMimeType() {
    var controller = new AnalysisController(new AnalysisService(new MockWasteDetectionService()));
    var file = new MockMultipartFile("image", "fake.png", "image/png", "not image".getBytes());
    assertEquals(
        400,
        assertThrows(ResponseStatusException.class, () -> controller.analyze(file, "multiple"))
            .getStatusCode()
            .value());
  }

  @Test
  void emptyOversizedAndUnknownJobsRejected() {
    var controller = new AnalysisController(new AnalysisService(new MockWasteDetectionService()));
    assertThrows(
        ResponseStatusException.class,
        () -> controller.analyze(new MockMultipartFile("image", new byte[0]), "multiple"));
    assertThrows(
        ResponseStatusException.class,
        () ->
            controller.analyze(
                new MockMultipartFile("image", new byte[10 * 1024 * 1024 + 1]), "multiple"));
    assertEquals(
        404,
        assertThrows(ResponseStatusException.class, () -> controller.get("missing"))
            .getStatusCode()
            .value());
  }

  @Test
  void mockOutageAndUnknownScenario() throws Exception {
    var controller = new AnalysisController(new AnalysisService(new MockWasteDetectionService()));
    assertEquals(
        503,
        assertThrows(ResponseStatusException.class, () -> controller.analyze(image(), "error"))
            .getStatusCode()
            .value());
    assertEquals(
        400,
        assertThrows(ResponseStatusException.class, () -> controller.analyze(image(), "invalid"))
            .getStatusCode()
            .value());
  }
}
