package np.chitwancare.storage;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import javax.imageio.ImageIO;
import javax.imageio.stream.MemoryCacheImageInputStream;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

/** Local development storage. Only server-generated keys can be opened or deleted. */
@Component
public class LocalImageStorage implements ImageStorage {
  public static final int MAX_BYTES = 10 * 1024 * 1024;
  private final Path root;

  public LocalImageStorage(@Value("${app.storage.directory:./uploads}") String directory) {
    root = Path.of(directory).toAbsolutePath().normalize();
  }

  @Override
  public StoredImage store(
      InputStream content, String originalFilename, String contentType, long size)
      throws IOException {
    if (size <= 0) throw invalid("Select a non-empty image.");
    if (size > MAX_BYTES)
      throw new ResponseStatusException(
          HttpStatus.PAYLOAD_TOO_LARGE, "Image must be at most 10 MB.");
    if (!Set.of("image/jpeg", "image/png").contains(Objects.requireNonNullElse(contentType, "")))
      throw invalid("Upload a JPEG or PNG image.");
    byte[] bytes = content.readNBytes(MAX_BYTES + 1);
    if (bytes.length > MAX_BYTES)
      throw new ResponseStatusException(
          HttpStatus.PAYLOAD_TOO_LARGE, "Image must be at most 10 MB.");
    String extension;
    try (var input = new MemoryCacheImageInputStream(new ByteArrayInputStream(bytes))) {
      var readers = ImageIO.getImageReaders(input);
      if (!readers.hasNext()) throw invalid("The file is not a readable JPEG or PNG image.");
      var reader = readers.next();
      try {
        reader.setInput(input, true, true);
        String format = reader.getFormatName().toLowerCase(Locale.ROOT);
        extension = format.equals("jpeg") ? "jpg" : format;
        if (!(format.equals("jpeg") || format.equals("png"))
            || !contentType.equals("image/" + format))
          throw invalid("Image contents do not match the declared type.");
        if ((long) reader.getWidth(0) * reader.getHeight(0) > 40_000_000)
          throw invalid("Image resolution is too large. Choose an image below 40 megapixels.");
        if (reader.read(0) == null) throw invalid("The image is damaged.");
      } finally {
        reader.dispose();
      }
    } catch (IOException | IllegalArgumentException ex) {
      throw invalid("The image is damaged or unsupported.");
    }
    Files.createDirectories(root);
    String key = UUID.randomUUID() + "." + extension;
    Path path = resolve(key);
    try {
      Files.write(path, bytes, StandardOpenOption.CREATE_NEW);
    } catch (IOException ex) {
      Files.deleteIfExists(path);
      throw ex;
    }
    return new StoredImage(key, contentType, bytes.length);
  }

  private Path resolve(String key) throws IOException {
    if (key == null
        || !key.matches("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.(jpg|png)"))
      throw new IOException("Invalid storage key");
    Path path = root.resolve(key).normalize();
    if (!path.getParent().equals(root) || Files.isSymbolicLink(path))
      throw new IOException("Invalid storage path");
    return path;
  }

  @Override
  public InputStream open(String key) throws IOException {
    return Files.newInputStream(resolve(key), LinkOption.NOFOLLOW_LINKS);
  }

  @Override
  public void delete(String key) throws IOException {
    Files.deleteIfExists(resolve(key));
  }

  private ResponseStatusException invalid(String message) {
    return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
  }
}
