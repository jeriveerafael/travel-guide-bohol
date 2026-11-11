-- Run once on an existing Bohol tourism database that was created before the
-- travel-guide fields were added. Fresh installs already include these columns
-- in database.sql.
--
-- phpMyAdmin: select bohol_tourism_db, open the SQL tab, paste, and run.

USE bohol_tourism_db;

ALTER TABLE destinations
  ADD COLUMN contact_info VARCHAR(500) NULL AFTER tips,
  ADD COLUMN activities TEXT NULL AFTER contact_info,
  ADD COLUMN accommodations TEXT NULL AFTER activities;
