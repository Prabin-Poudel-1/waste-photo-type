package np.chitwancare.analysis;

import java.io.*;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import javax.imageio.ImageIO;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

// Phase 1 local development only: no public deployment before authentication/ownership checks.
@Service
public class AnalysisService {
  private final WasteDetectionService service;
  private final Map<String, DetectionResult> results = new ConcurrentHashMap<>();

  public AnalysisService(WasteDetectionService service) {
    this.service = service;
  }

  public synchronized DetectionResult analyze(MultipartFile image, String scenario)
      throws IOException {
    if (image.isEmpty() || image.getSize() > 10 * 1024 * 1024)
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST, "Choose a JPEG or PNG image under 10 MB.");
    byte[] bytes = image.getBytes();
    try (var input = ImageIO.createImageInputStream(new ByteArrayInputStream(bytes))) {
      if (input == null) throw new IOException();
      var readers = ImageIO.getImageReaders(input);
      if (!readers.hasNext())
        throw new ResponseStatusException(
            HttpStatus.BAD_REQUEST, "This file is not a supported JPEG or PNG image.");
      var reader = readers.next();
      try {
        reader.setInput(input);
        String format = reader.getFormatName();
        if (!(format.equalsIgnoreCase("JPEG") || format.equalsIgnoreCase("PNG"))
            || (long) reader.getWidth(0) * reader.getHeight(0) > 24000000)
          throw new ResponseStatusException(
              HttpStatus.BAD_REQUEST, "Use a JPEG or PNG image up to 24 megapixels.");
        if (reader.read(0) == null) throw new IOException();
      } finally {
        reader.dispose();
      }
    } catch (ResponseStatusException e) {
      throw e;
    } catch (IOException | RuntimeException e) {
      throw new ResponseStatusException(
          HttpStatus.BAD_REQUEST, "The image could not be read. Choose another photo.");
    }
    results.values().removeIf(r -> r.analyzedAt().isBefore(Instant.now().minusSeconds(1800)));
    if (results.size() >= 200)
      throw new ResponseStatusException(
          HttpStatus.TOO_MANY_REQUESTS,
          "The local demo is full. Try later or restart the demo server.");
    var result = service.analyze(bytes, scenario);
    results.put(result.id(), result);
    return result;
  }

  public DetectionResult get(String id) {
    var result = results.get(id);
    if (result == null || result.analyzedAt().isBefore(Instant.now().minusSeconds(1800)))
      throw new ResponseStatusException(
          HttpStatus.NOT_FOUND, "Analysis expired. Analyze your photo again.");
    return result;
  }
}
