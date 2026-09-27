package np.chitwancare.service;

import java.io.IOException;
import java.util.*;
import np.chitwancare.dto.*;
import np.chitwancare.entity.*;
import np.chitwancare.enums.*;
import np.chitwancare.exception.ResourceNotFoundException;
import np.chitwancare.mapper.WasteReportMapper;
import np.chitwancare.repository.*;
import np.chitwancare.storage.ImageStorage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.multipart.MultipartFile;

@Service
public class AuthorityReportService {
  private final ReportAccessService access;
  private final WasteReportService reportsService;
  private final WasteReportRepository reports;
  private final ReportStatusHistoryRepository history;
  private final ReportImageRepository images;
  private final WasteReportMapper mapper;
  private final ImageStorage storage;
  private final ReportAssignmentRepository assignments;
  private final DepartmentRepository departments;
  public AuthorityReportService(ReportAccessService access, WasteReportService reportsService,
      WasteReportRepository reports, ReportStatusHistoryRepository history,
      ReportImageRepository images, WasteReportMapper mapper, ImageStorage storage, ReportAssignmentRepository assignments, DepartmentRepository departments) {
    this.access=access; this.reportsService=reportsService; this.reports=reports;
    this.assignments=assignments; this.departments=departments; this.history=history; this.images=images; this.mapper=mapper; this.storage=storage;
  }
  @Transactional(readOnly=true)
  public PageResponse<WasteReportResponse> list(int page,int size) {
    var actor=access.requireAuthority();
    if (actor.getRole()==Role.ADMIN) return reportsService.list(page,size);
    if(page<0 || size<1 || size>100) throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"Invalid pagination.");
    var result=reports.findAssigned(access.departmentId(actor), org.springframework.data.domain.PageRequest.of(page,size,
        org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Order.desc("createdAt"),org.springframework.data.domain.Sort.Order.desc("id"))));
    return new PageResponse<>(result.getContent().stream().map(mapper::toResponse).toList(),page,size,result.getTotalElements(),result.getTotalPages());
  }
  @Transactional
  public WasteReportResponse assign(long id,long departmentId,String note) {
    var actor=access.requireAuthority();
    if(actor.getRole()!=Role.ADMIN) throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Only administrators assign reports.");
    var report=reports.findForUpdate(id).orElseThrow(() -> new ResourceNotFoundException("Report not found."));
    if(report.getCurrentStatus()!=ReportStatus.VERIFIED) throw new ResponseStatusException(HttpStatus.CONFLICT,"Only verified reports can be assigned.");
    var department=departments.findById(departmentId).filter(Department::isActive)
        .orElseThrow(() -> new ResourceNotFoundException("Active department not found."));
    assignments.findByReportIdAndActiveTrue(id).forEach(a -> a.setActive(false));
    var assignment=new ReportAssignment(); assignment.setReport(report); assignment.setDepartment(department); assignment.setAssignedBy(actor);
    assignments.save(assignment);
    report.setCurrentStatus(ReportStatus.ASSIGNED);
    var entry=new ReportStatusHistory(); entry.setStatus(ReportStatus.ASSIGNED); entry.setChangedBy(actor);
    entry.setNote("Assigned to " + department.getName() + (note==null || note.isBlank()?"":". " + note.trim()));
    report.addHistory(entry); history.save(entry); reports.flush(); return mapper.toResponse(report);
  }
  @Transactional
  public WasteReportResponse change(long id,ReportStatus next,String note,MultipartFile file) {
    var actor=access.requireAuthority();
    if(actor.getRole()==Role.ADMIN && (file!=null || !(next==ReportStatus.VERIFIED || next==ReportStatus.REJECTED)))
      throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Administrators verify, assign or reject; departments perform cleanup.");
    if(actor.getRole()==Role.DEPARTMENT && !(next==ReportStatus.IN_PROGRESS || next==ReportStatus.RESOLVED))
      throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Departments may only start or resolve assigned work.");
    var report=reports.findForUpdate(id).orElseThrow(() -> new ResourceNotFoundException("Report not found."));
    if(actor.getRole()==Role.DEPARTMENT) access.requireAssigned(actor,report);
    if (!allowed(report.getCurrentStatus()).contains(next))
      throw new ResponseStatusException(HttpStatus.CONFLICT,"Status changed or transition is not allowed. Refresh the report.");
    if (next==ReportStatus.RESOLVED && file==null)
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST,"A cleanup photo is required to resolve this report.");
    if (file!=null) {
      try (var input=file.getInputStream()) {
        var stored=storage.store(input,file.getOriginalFilename(),file.getContentType(),file.getSize());
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
          @Override public void afterCompletion(int status) {
            if(status!=STATUS_COMMITTED) try { storage.delete(stored.storageKey()); }
            catch(IOException ex) { org.slf4j.LoggerFactory.getLogger(AuthorityReportService.class).error("Cleanup image rollback deletion failed"); }
          }
        });
        var image=new ReportImage(); image.setImageType(ImageType.AFTER_CLEANUP);
        image.setStorageKey(stored.storageKey()); image.setContentType(stored.contentType());
        String name=Objects.requireNonNullElse(file.getOriginalFilename(),"cleanup").replace('\\','/');
        name=name.substring(name.lastIndexOf('/')+1).replaceAll("[^a-zA-Z0-9._ -]","_");
        if(name.isBlank()) name="cleanup";
        image.setOriginalFilename(name.substring(0,Math.min(255,name.length())));
        report.addImage(image); images.save(image);
      } catch(IOException ex) {
        throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,"Cleanup photo could not be saved. Retry.");
      }
    }
    report.setCurrentStatus(next);
    var entry=new ReportStatusHistory(); entry.setStatus(next); entry.setChangedBy(actor);
    entry.setNote(note==null?null:note.trim()); report.addHistory(entry); history.save(entry);
    reports.flush();
    return mapper.toResponse(report);
  }
  private Set<ReportStatus> allowed(ReportStatus current) {
    return switch(current) {
      case SUBMITTED -> Set.of(ReportStatus.VERIFIED,ReportStatus.REJECTED);
      case AI_ANALYZED,PENDING_VERIFICATION -> Set.of(ReportStatus.VERIFIED,ReportStatus.REJECTED);
      case VERIFIED -> Set.of(ReportStatus.ASSIGNED,ReportStatus.REJECTED);
      case ASSIGNED -> Set.of(ReportStatus.IN_PROGRESS,ReportStatus.REJECTED);
      case IN_PROGRESS -> Set.of(ReportStatus.RESOLVED,ReportStatus.REJECTED);
      case RESOLVED,REJECTED -> Set.of();
    };
  }
}
