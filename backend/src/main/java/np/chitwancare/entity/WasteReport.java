package np.chitwancare.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import np.chitwancare.enums.ReportStatus;
import np.chitwancare.enums.Severity;

@Entity
@Table(name = "waste_reports")
public class WasteReport extends MutableEntity {
    @OneToMany(mappedBy = "report", cascade = CascadeType.PERSIST)
    @OrderBy("id ASC")
    private List<ReportImage> images = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tourist_spot_id")
    private TouristSpot touristSpot;

    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "reporter_id", nullable = true)
    private AppUser reporter;

    @Column(name = "description", length = 2000, nullable = true)
    private String description;

    @Column(nullable = false, precision = 9, scale = 6)
    private BigDecimal latitude;

    @Column(nullable = false, precision = 9, scale = 6)
    private BigDecimal longitude;

    @Column(name = "address", length = 500, nullable = true)
    private String address;

    @Enumerated(EnumType.STRING)
    @Column(name = "severity", length = 20, nullable = false)
    private Severity severity;

    @Enumerated(EnumType.STRING)
    @Column(name = "current_status", length = 30, nullable = false)
    private ReportStatus currentStatus;

    @OneToMany(mappedBy = "report", cascade = CascadeType.PERSIST)
    @OrderBy("id ASC")
    private List<WasteDetection> detections = new ArrayList<>();

    @OneToMany(mappedBy = "report", cascade = CascadeType.PERSIST)
    @OrderBy("createdAt ASC, id ASC")
    private List<ReportStatusHistory> statusHistory = new ArrayList<>();

    public List<ReportImage> getImages() {
        return Collections.unmodifiableList(images);
    }

    public void addImage(ReportImage image) {
        image.setReport(this);
        images.add(image);
    }

    public TouristSpot getTouristSpot() {
        return touristSpot;
    }

    public void setTouristSpot(TouristSpot value) {
        touristSpot = value;
    }

    public List<WasteDetection> getDetections() {
        return Collections.unmodifiableList(detections);
    }

    public List<ReportStatusHistory> getStatusHistory() {
        return Collections.unmodifiableList(statusHistory);
    }

    public void addDetection(WasteDetection value) {
        value.setReport(this);
        detections.add(value);
    }

    public void addHistory(ReportStatusHistory value) {
        value.setReport(this);
        statusHistory.add(value);
    }

    public AppUser getReporter() {
        return reporter;
    }

    public void setReporter(AppUser value) {
        this.reporter = value;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String value) {
        this.description = value;
    }

    public BigDecimal getLatitude() {
        return latitude;
    }

    public void setLatitude(BigDecimal value) {
        this.latitude = value;
    }

    public BigDecimal getLongitude() {
        return longitude;
    }

    public void setLongitude(BigDecimal value) {
        this.longitude = value;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String value) {
        this.address = value;
    }

    public Severity getSeverity() {
        return severity;
    }

    public void setSeverity(Severity value) {
        this.severity = value;
    }

    public ReportStatus getCurrentStatus() {
        return currentStatus;
    }

    public void setCurrentStatus(ReportStatus value) {
        this.currentStatus = value;
    }
}// Placeholder: paste the contents of backend/src/main/java/np/chitwancare/entity/WasteReport.java from your app here.
