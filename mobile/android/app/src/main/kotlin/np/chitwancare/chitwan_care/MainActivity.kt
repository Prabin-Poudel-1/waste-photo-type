package np.chitwancare.chitwan_care

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var detector: WasteInferenceBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        detector = WasteInferenceBridge(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        detector?.close()
        detector = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}// Placeholder: paste the contents of mobile/android/app/src/main/kotlin/np/chitwancare/chitwan_care/MainActivity.kt from your app here.
