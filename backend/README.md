# Local backend

Run `sh scripts/start-local.sh` from the repository root. It loads the template's ignored `.env`, starts its PostgreSQL container and starts Spring Boot on port 8082. The schema is created by Flyway migrations. The original project's database is not used.

See the root README for registration, admin/department setup and USB/emulator access. JWT credentials and uploaded files stay local and ignored. Tests were restored as source but were not run during this update.
