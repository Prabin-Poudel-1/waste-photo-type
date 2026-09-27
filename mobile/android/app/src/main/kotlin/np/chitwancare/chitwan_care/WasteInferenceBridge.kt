// Placeholder: paste the contents of mobile/android/app/src/main/kotlin/np/chitwancare/chitwan_care/WasteInferenceBridge.kt from your app here.
package np.chitwancare.chitwan_care

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.ai.edge.litert.Accelerator
import com.google.ai.edge.litert.CompiledModel
import com.google.ai.edge.litert.TensorBuffer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Model and buffers belong to one worker; inference stays off the UI thread. */
class WasteInferenceBridge(
    private val context: Context,
    messenger: BinaryMessenger
) {
    private val channel =
        MethodChannel(messenger, "np.chitwancare/waste_inference")

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val busy = AtomicBoolean(false)

    private var model: CompiledModel? = null
    private var inputs: List<TensorBuffer> = emptyList()
    private var outputs: List<TensorBuffer> = emptyList()

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "infer") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val bytes = call.arguments as? ByteArray

            if (bytes == null || bytes.size != 3 * 640 * 640 * 4) {
                result.error("INPUT", "Invalid model input.", null)
                return@setMethodCallHandler
            }

            if (!busy.compareAndSet(false, true)) {
                result.error("BUSY", "Analysis already running.", null)
                return@setMethodCallHandler
            }

            worker.execute {
                try {
                    initialize()

                    val values = FloatArray(bytes.size / 4)
                    ByteBuffer.wrap(bytes)
                        .order(ByteOrder.LITTLE_ENDIAN)
                        .asFloatBuffer()
                        .get(values)

                    inputs[0].writeFloat(values)
                    model!!.run(inputs, outputs)

                    val output = outputs[0].readFloat()

                    check(
                        output.size == 9 * 8400 &&
                                output.all { it.isFinite() }
                    )

                    val buffer = ByteBuffer
                        .allocate(output.size * 4)
                        .order(ByteOrder.LITTLE_ENDIAN)

                    buffer.asFloatBuffer().put(output)

                    main.post {
                        result.success(buffer.array())
                    }
                } catch (e: Exception) {
                    android.util.Log.e(
                        "WasteInference",
                        "On-device analysis failed",
                        e
                    )

                    release()

                    main.post {
                        result.error(
                            "INFERENCE",
                            "On-device analysis could not finish. Please retry.",
                            null
                        )
                    }
                } finally {
                    busy.set(false)
                }
            }
        }
    }

    private fun initialize() {
        if (model != null) return

        val file = File(
            context.cacheDir,
            "waste-model-a87e1887.tflite"
        )

        // Copy the exact bundled model during initialization.
        context.assets.open("chitwan_care_waste_model.tflite").use { source ->
            file.outputStream().use { destination ->
                source.copyTo(destination)
            }
        }

        val options = CompiledModel.Options(Accelerator.CPU)
        options.cpuOptions = CompiledModel.CpuOptions(numThreads = 2)

        model = CompiledModel.create(file.absolutePath, options)

        check(
            model!!.getInputTensorType(inputName = "args_0")
                .layout!!.dimensions.toList() == listOf(1, 3, 640, 640)
        )

        check(
            model!!.getOutputTensorType(outputName = "output_0")
                .layout!!.dimensions.toList() == listOf(1, 9, 8400)
        )

        check(
            model!!.getInputTensorType(inputName = "args_0")
                .elementType.toString() == "FLOAT"
        )

        check(
            model!!.getOutputTensorType(outputName = "output_0")
                .elementType.toString() == "FLOAT"
        )

        inputs = model!!.createInputBuffers()
        outputs = model!!.createOutputBuffers()
    }

    private fun release() {
        inputs.forEach { runCatching { it.close() } }
        outputs.forEach { runCatching { it.close() } }

        inputs = emptyList()
        outputs = emptyList()

        runCatching { model?.close() }
        model = null
    }

    fun close() {
        channel.setMethodCallHandler(null)
        worker.execute { release() }
        worker.shutdown()
    }
}