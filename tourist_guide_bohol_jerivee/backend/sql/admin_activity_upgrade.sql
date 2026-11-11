-- Run this once in phpMyAdmin if your existing database was created
-- before the admin user/activity features were added.
USE bohol_tourism_db;

CREATE TABLE IF NOT EXISTS activity_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  event_type VARCHAR(60) NOT NULL,
  description VARCHAR(255) NOT NULL,
  entity_type VARCHAR(60) NULL,
  entity_id VARCHAR(90) NULL,
  metadata_json TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_activity_logs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_activity_user_created (user_id, created_at),
  INDEX idx_activity_type_created (event_type, created_at),
  INDEX idx_activity_created (created_at)
) ENGINE=InnoDB;
