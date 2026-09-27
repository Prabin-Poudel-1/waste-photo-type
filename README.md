# Chitwan Care 

This is a folder/file scaffold, not a working app yet. Paste your implementation into the placeholder files with the same names. Application source, tests, SQL migrations and custom scripts contain placeholders. Build configuration, dependency manifests/locks, Maven/Gradle wrappers, platform resources, images and the model asset are retained.

Start with `mobile/lib/` for Flutter and `backend/src/main/java/` for Java. Also restore your native inference files in `mobile/android/app/src/main/kotlin/`, database migrations, tests and custom scripts as needed. Keep the configuration in this template rather than copying private configuration from the original project.

Use your existing installed Flutter, Android Studio, Java and Docker; nothing was installed. Dependency caches, generated build files, local SDK paths, Git history, database exports, uploaded reports and private credential files were excluded. Tools may regenerate local files/download project dependencies when you eventually run the project.

The local database is separately named `chitwan_care_template`, exposed on port 54330, with a separate Compose volume. Backend port is 8082. Configure a new local DB_PASSWORD and JWT_SECRET before running. When restoring app API configuration, point it at this backend rather than the original/hosted backend (Android emulator: http://10.0.2.2:8082). Do not reuse the original database URL or hosted credentials.

The original Desktop/chitwan-care folder was not changed. No Git repository was initialized, no builds/tests were run, and no database was started.
