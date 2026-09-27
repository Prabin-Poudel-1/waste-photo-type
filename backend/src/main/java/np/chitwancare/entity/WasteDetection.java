package np.chitwancare.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;

@Entity
@Table(name = "waste_detections")
public class WasteDetection extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "report_id", nullable = false)
    private WasteReport report;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "waste_category_id", nullable = false)
    private WasteCategory wasteCategory;

    @Column(name = "detected_label", length = 100, nullable = false)
    private String detectedLabel;

    @Column(nullable = false, precision = 7, scale = 6)
    private BigDecimal confidence;

    public WasteReport getReport() {
        return report;
    }

    public void setReport(WasteReport value) {
        this.report = value;
    }

    public WasteCategory getWasteCategory() {
        return wasteCategory;
    }

    public void setWasteCategory(WasteCategory value) {
        this.wasteCategory = value;
    }

    public String getDetectedLabel() {
        return detectedLabel;
    }

    public void setDetectedLabel(String value) {
        this.detectedLabel = value;
    }

    public BigDecimal getConfidence() {
        return confidence;
    }

    public void setConfidence(BigDecimal value) {
        this.confidence = value;
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/entity/WasteDetection.java from your app here.
