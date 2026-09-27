# Phase 1 analysis contract

Flutter never calls FastAPI directly. UI → Riverpod controller → AnalysisRepository → WasteDetectionService. The local mock and HTTP adapters produce the same DetectionResult. The Spring backend has its own WasteDetectionService abstraction; the current adapter is a deterministic mock. A future authenticated HTTP adapter will call FastAPI, validate its response, map labels to configured category codes, and retain this public mobile contract.

## POST /api/v1/analyses

Multipart fields:
- image: JPEG/PNG, up to 10 MB and 24 megapixels.
- scenario: multiple, none, low, or error. Development-only; remove client-controlled mock scenarios when enabling a real inference provider.

Returns 202 with a completed result in Phase 1. The Flutter HTTP adapter also supports polling an id when a later implementation returns UPLOADED or PROCESSING; FAILED is terminal. Schema changes must be versioned.

```json
{
  "id": "uuid",
  "status": "COMPLETED",
  "schemaVersion": 1,
  "modelVersion": "mock-v1",
  "isMock": true,
  "wasteDetected": true,
  "detections": [
    {"categoryCode": "plastic", "label": "Plastic", "confidence": 0.94},
    {"categoryCode": "organic", "label": "Organic", "confidence": 0.82}
  ],
  "analyzedAt": "2026-09-22T00:00:00Z"
}
```

## GET /api/v1/analyses/{id}

Returns the result until its 30-minute in-memory expiration or server restart. Unknown/expired ids return 404. This is not report storage.

Errors use `{"message":"Useful explanation"}` with 400 invalid image/scenario, 413 too large, 429 full local result cache, 503 simulated service failure. HTTP adapter handles unreachable servers/timeouts and malformed responses; it never interprets an error as an empty detection.

## Later FastAPI contract

Internal POST /v1/detections receives image bytes plus a request identifier, returns schema version, model version, detections and scores, with optional normalized bounding boxes. No AI-generated department assignments or report state transitions. The backend controls confidence validation, category mapping, authentication, image ownership and business workflow. Inference timeout/failure must remain distinct from “no waste”.

## Security boundaries

Both Phase 1 modes are for development. The Spring demo has no login/ownership checks yet and binds to loopback by default. Do not deploy it publicly. The server decodes images and rejects invalid content irrespective of extension/MIME. Images are not written to disk or database. No original EXIF data is used for incident location; location confirmation belongs in Phase 2. Back navigation discards late UI responses but does not promise cancellation of already-started server work.
