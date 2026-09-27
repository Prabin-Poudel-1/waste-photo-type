package np.chitwancare.service;

import java.io.IOException;
import np.chitwancare.exception.ResourceNotFoundException;
import np.chitwancare.repository.ReportImageRepository;
import np.chitwancare.storage.ImageStorage;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ReportImageService {
  private final ReportImageRepository images;
  private final ImageStorage storage;
  private final ReportAccessService access;

  public ReportImageService(ReportImageRepository images, ImageStorage storage, ReportAccessService access) {
    this.images = images;
    this.storage = storage;
    this.access = access;
  }

  public record Download(byte[] bytes, String contentType) {}

  @Transactional(readOnly = true)
  public Download get(long reportId, long imageId) {
    var image =
        images
            .findById(imageId)
            .filter(i -> i.getReport().getId().equals(reportId))
            .orElseThrow(() -> new ResourceNotFoundException("Report image not found."));
    access.requireReadable(image.getReport());
    try (var stream = storage.open(image.getStorageKey())) {
      return new Download(stream.readAllBytes(), image.getContentType());
    } catch (IOException ex) {
      throw new ResponseStatusException(
          HttpStatus.SERVICE_UNAVAILABLE, "Image temporarily unavailable.");
    }
  }
}
