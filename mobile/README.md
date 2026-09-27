# Android application

From the repository root, start `sh scripts/start-local.sh`, then in another terminal run `sh scripts/run-android.sh`. Connect one Android emulator or one USB-debugging phone; pass the device serial if several are attached.

The launcher forwards port 8082 through adb and starts a debug build with local backend configuration. Open this `mobile` directory in Android Studio. See the root README for green Run button settings and setup. Real inference is Android-only; web preview uses mock mode.
