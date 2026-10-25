-- =============================================================================
-- Migration: Add Role-Based Access Control (RBAC) Column to 'users'
-- Database: auth_db
-- =============================================================================

USE auth_db;

-- 1. Safely add the 'role' column with default value 'user'
ALTER TABLE users
  ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'user' AFTER password_hash;

-- 2. Add CHECK constraint to restrict valid roles to 'admin' and 'user'
ALTER TABLE users
  ADD CONSTRAINT chk_user_role CHECK (role IN ('admin', 'user'));

-- 3. Optional: Create index on role column for efficient role filtering
CREATE INDEX idx_users_role ON users(role);
