package np.chitwancare.analysis;

public interface WasteDetectionService {
  DetectionResult analyze(byte[] image, String scenario);
}
