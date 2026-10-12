module.exports = async (pool, ensureColumn) => {
  await ensureColumn('users', 'is_blocked', 'BOOLEAN NOT NULL DEFAULT FALSE');
  await ensureColumn('users', 'block_reason', 'VARCHAR(500) NULL');
  await ensureColumn('users', 'blocked_at', 'DATETIME NULL');
  await ensureColumn(
    'user_subscriptions',
    'source',
    "VARCHAR(30) NOT NULL DEFAULT 'checkout'",
  );
  await ensureColumn('user_subscriptions', 'admin_note', 'VARCHAR(500) NULL');
  await pool.query(`CREATE TABLE IF NOT EXISTS admin_audit_log (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    admin_id BIGINT UNSIGNED NOT NULL, admin_name VARCHAR(120) NOT NULL,
    admin_email VARCHAR(191) NOT NULL, action VARCHAR(80) NOT NULL,
    entity VARCHAR(80) NOT NULL, entity_id VARCHAR(100) NULL,
    reason VARCHAR(500) NULL, before_data JSON NULL, after_data JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY audit_created (created_at, id), KEY audit_target (entity, entity_id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
  await pool.query(`CREATE TABLE IF NOT EXISTS admin_media (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    original_name VARCHAR(255) NOT NULL, path VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL, size_bytes INT UNSIGNED NOT NULL,
    admin_id BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
  await pool.query(`CREATE TABLE IF NOT EXISTS admin_bulk_previews (
    id CHAR(36) NOT NULL PRIMARY KEY, admin_id BIGINT UNSIGNED NOT NULL,
    resource VARCHAR(80) NOT NULL, operation VARCHAR(30) NOT NULL,
    payload JSON NOT NULL, snapshots JSON NOT NULL, result JSON NULL,
    expires_at DATETIME NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    applied_at DATETIME NULL, KEY bulk_expiry (expires_at)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
};
