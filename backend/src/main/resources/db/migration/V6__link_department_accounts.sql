-- Nullable membership preserves all existing accounts and reports.
ALTER TABLE app_users ADD COLUMN department_id BIGINT REFERENCES departments(id);
CREATE INDEX idx_app_users_department ON app_users(department_id);
CREATE INDEX idx_assignment_department_active ON report_assignments(department_id, report_id) WHERE active;
