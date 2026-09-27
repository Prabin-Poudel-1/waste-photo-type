package np.chitwancare.storage;

import java.io.IOException;
import java.io.InputStream;

// Storage keys are opaque; implementations must validate content and prevent path traversal.
// Local development implementation can later be replaced by object storage.
public interface ImageStorage {
  StoredImage store(InputStream content, String originalFilename, String contentType, long size)
      throws IOException;

  InputStream open(String storageKey) throws IOException;

  void delete(String storageKey) throws IOException;

  record StoredImage(String storageKey, String contentType, long size) {}
}
