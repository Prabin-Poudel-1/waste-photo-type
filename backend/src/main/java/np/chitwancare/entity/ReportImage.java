package np.chitwancare.entity;

import jakarta.persistence.*;
import java.util.*;
import np.chitwancare.enums.*;

@Entity
@Table(name = "report_images")
public class ReportImage extends BaseEntity {
  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "report_id", nullable = false)
  private WasteReport report;

  @Enumerated(EnumType.STRING)
  @Column(name = "image_type", length = 30, nullable = false)
  private ImageType imageType;

  @Column(name = "storage_key", length = 500, nullable = false)
  private String storageKey;

  @Column(name = "original_filename", length = 255, nullable = false)
  private String originalFilename;

  @Column(name = "content_type", length = 100, nullable = false)
  private String contentType;

  public WasteReport getReport() {
    return report;
  }

  public void setReport(WasteReport value) {
    this.report = value;
  }

  public ImageType getImageType() {
    return imageType;
  }

  public void setImageType(ImageType value) {
    this.imageType = value;
  }

  public String getStorageKey() {
    return storageKey;
  }

  public void setStorageKey(String value) {
    this.storageKey = value;
  }

  public String getOriginalFilename() {
    return originalFilename;
  }

  public void setOriginalFilename(String value) {
    this.originalFilename = value;
  }

  public String getContentType() {
    return contentType;
  }

  public void setContentType(String value) {
    this.contentType = value;
  }
}
