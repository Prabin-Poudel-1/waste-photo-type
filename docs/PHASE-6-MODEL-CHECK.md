# Phase 6 blocked: supplied model runtime compatibility

No production detection code was changed. The supplied model was not modified.

Input: serving_default_args_0, FLOAT32 [1,3,640,640] (NCHW).
Output: serving_default_output_0_output_dequant, FLOAT32 [1,11,8400].
Both exposed tensors have no quantization parameters in the FlatBuffer;
the runtime reports scale=0, zeroPoint=0 (not applicable to FLOAT32).
Internal operators/weights are quantized INT8 despite float inputs/outputs.

Embedded Ultralytics metadata: version 8.4.163, task detect, head Detect,
end2end=false. Classes: cardboard, miscellaneous, organic, paper, glass,
metal, plastic (IDs 0–6). The output graph produces normalized center-x,
center-y,width,height and seven sigmoid class scores, without an objectness channel.
The final coordinate multiplier dequantizes to 1/640.

Targeted test: flutter_litert 3.9.2 CPU Interpreter on macOS; model creation and
tensor allocation succeeded, then invocation with a correctly sized Float32 input
failed: "ERROR: Input tensor 149 lacks data"; TfLiteInterpreterInvoke returned
TfLiteStatus=1 (kTfLiteError).

Tensor 149 is an INT8 convolution weight tensor [32,3,3,16]. Its buffer has zero
inline bytes and references external data at file offset 3300448, size 4608.
This establishes a failure in this runtime/export combination, not proof of a
corrupt model or of failure in every runtime. No speculative decoder, alternative
runtime trials, retraining or conversion was attempted.

Request a self-contained compatible TFLite export from the model owner, or their
exact validated inference runtime/version and export command. Confirm it invokes
successfully before implementing preprocessing/decoding/UI integration.

Temporary runtime smoke test was removed, and the added flutter_litert/image direct
dependencies were removed. Existing mock detection remains unchanged: Phase 6 is
NOT complete. No full suites, backend tests or Android builds were run.

Model SHA256: 024d0b6a67e2437b53ee58cbcb000d0d3288df48ded2ce0e91ac7a386b970090
