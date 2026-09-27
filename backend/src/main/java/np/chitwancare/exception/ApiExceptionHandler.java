package np.chitwancare.exception;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import java.time.Instant;
import java.util.*;
import np.chitwancare.dto.ApiErrorResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

@RestControllerAdvice
public class ApiExceptionHandler {
  private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

  private ResponseEntity<ApiErrorResponse> response(
      HttpStatus status, String message, HttpServletRequest request, Map<String, String> fields) {
    return ResponseEntity.status(status)
        .body(
            new ApiErrorResponse(
                Instant.now(),
                status.value(),
                status.getReasonPhrase(),
                message,
                request.getRequestURI(),
                fields));
  }

  @ExceptionHandler(ResourceNotFoundException.class)
  ResponseEntity<ApiErrorResponse> missing(
      ResourceNotFoundException ex, HttpServletRequest request) {
    return response(HttpStatus.NOT_FOUND, ex.getMessage(), request, Map.of());
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ApiErrorResponse> validation(
      MethodArgumentNotValidException ex, HttpServletRequest request) {
    Map<String, String> errors = new TreeMap<>();
    ex.getBindingResult()
        .getFieldErrors()
        .forEach(
            e ->
                errors.putIfAbsent(
                    e.getField(),
                    Objects.requireNonNullElse(e.getDefaultMessage(), "Invalid value")));
    return response(HttpStatus.BAD_REQUEST, "Request validation failed.", request, errors);
  }

  @ExceptionHandler(ConstraintViolationException.class)
  ResponseEntity<ApiErrorResponse> constraints(
      ConstraintViolationException ex, HttpServletRequest request) {
    Map<String, String> errors = new TreeMap<>();
    ex.getConstraintViolations()
        .forEach(e -> errors.put(e.getPropertyPath().toString(), e.getMessage()));
    return response(HttpStatus.BAD_REQUEST, "Request validation failed.", request, errors);
  }

  @ExceptionHandler({
    HttpMessageNotReadableException.class,
    MethodArgumentTypeMismatchException.class,
    HandlerMethodValidationException.class,
    MissingServletRequestPartException.class
  })
  ResponseEntity<ApiErrorResponse> malformed(Exception ex, HttpServletRequest request) {
    return response(
        HttpStatus.BAD_REQUEST,
        "Malformed request or invalid field/enum value.",
        request,
        Map.of());
  }

  @ExceptionHandler(DataIntegrityViolationException.class)
  ResponseEntity<ApiErrorResponse> conflict(
      DataIntegrityViolationException ex, HttpServletRequest request) {
    return response(
        HttpStatus.CONFLICT,
        "The request conflicts with existing data or a database constraint.",
        request,
        Map.of());
  }

  @ExceptionHandler(ResponseStatusException.class)
  ResponseEntity<ApiErrorResponse> status(ResponseStatusException ex, HttpServletRequest request) {
    return response(
        HttpStatus.valueOf(ex.getStatusCode().value()),
        Objects.requireNonNullElse(ex.getReason(), "Request failed."),
        request,
        Map.of());
  }

  @ExceptionHandler(MaxUploadSizeExceededException.class)
  ResponseEntity<ApiErrorResponse> size(Exception ex, HttpServletRequest request) {
    return response(
        HttpStatus.PAYLOAD_TOO_LARGE, "The image exceeds the upload limit.", request, Map.of());
  }

  @ExceptionHandler(NoResourceFoundException.class)
  ResponseEntity<ApiErrorResponse> noRoute(Exception ex, HttpServletRequest request) {
    return response(HttpStatus.NOT_FOUND, "Resource not found.", request, Map.of());
  }

  @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
  ResponseEntity<ApiErrorResponse> method(Exception ex, HttpServletRequest request) {
    return response(HttpStatus.METHOD_NOT_ALLOWED, "HTTP method not supported.", request, Map.of());
  }

  @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
  ResponseEntity<ApiErrorResponse> media(Exception ex, HttpServletRequest request) {
    return response(
        HttpStatus.UNSUPPORTED_MEDIA_TYPE, "Unsupported content type.", request, Map.of());
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<ApiErrorResponse> unexpected(Exception ex, HttpServletRequest request) {
    // Log only the type: exception messages can contain SQL values or user data.
    log.error("Unhandled API failure: {}", ex.getClass().getSimpleName());
    return response(
        HttpStatus.INTERNAL_SERVER_ERROR,
        "An unexpected server error occurred.",
        request,
        Map.of());
  }
}
