const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const zlib = require('node:zlib');

const TABLES = ['categories', 'subcategories', 'courses', 'Content', 'Alphabets',
  'quizz', 'phonics_category', 'phonics_courses', 'Phonics', 'stories',
  'site_language', 'subsc_plans'];
const MEDIA_COLUMNS = new Set(['image', 'content_image', 'content_audio', 'word_audio',
  'ill_image', 'letter_sound', 'title_image', 'audio', 'q_audio', 'raf_audio',
  'waf_audio', 'sentence_sound', 'title_audio', 'audio_text_map', 'ca', 'o1', 'o2', 'o3']);
const VERSION = 'original-20260713-v1';
const MEDIA_ORIGIN = 'https://kids.langlex.com';

function loadCatalog() {
  const directory = path.resolve(__dirname, '../../../database/data');
  const bytes = fs.readFileSync(path.join(directory, 'original-content.json.gz'));
  const manifest = JSON.parse(fs.readFileSync(path.join(directory, 'original-content.manifest.json')));
  if (crypto.createHash('sha256').update(bytes).digest('hex') !== manifest.catalogSha256) {
    throw new Error('Original content checksum mismatch');
  }
  const catalog = JSON.parse(zlib.gunzipSync(bytes));
  if (catalog.version !== VERSION) throw new Error('Unsupported catalog version');
  for (const table of TABLES) {
    const data = catalog.tables[table];
    if (!data || data.rows.length !== manifest.counts[table] ||
        !data.columns.every((column) => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(column)) ||
        !data.rows.every((row) => row.length === data.columns.length)) {
      throw new Error(`Invalid original content table: ${table}`);
    }
  }
  return catalog;
}

function normalizeValue(table, column, value) {
  if (value === null) return '';
  if (table === 'quizz' && ['ca', 'o1', 'o2', 'o3'].includes(column) &&
      !/^(?:\/?media\/|https?:\/\/)/i.test(String(value).trim())) return value;
  if (MEDIA_COLUMNS.has(column)) {
    // The dump varies the case of this shared Hindi/Maithili illustration.
    const media = String(value).trim().replace(
      '/media/images/content_image/hindi-alphabet/oum.png',
      '/media/images/content_image/hindi-alphabet/oum.PNG',
    );
    if (!media || /^(null|none)$/i.test(media)) return '';
    if (/^\/?media\//.test(media)) return `${MEDIA_ORIGIN}/${media.replace(/^\//, '')}`;
    return media.replace(/^http:\/\/kids\.langlex\.com\//, `${MEDIA_ORIGIN}/`);
  }
  if (column.toLowerCase() === 'language') {
    const language = String(value).trim();
    return language.charAt(0).toUpperCase() + language.slice(1).toLowerCase();
  }
  if (table === 'subsc_plans') {
    // The source's permission descriptions are explicitly lorem-ipsum placeholders.
    if (column === 'permission') return '[]';
    if (column === 'type') return String(value).toLowerCase();
    if (column === 'amount' && value === '') return '0';
  }
  return value;
}

async function importOriginalContent(pool) {
  const catalog = loadCatalog();
  await pool.query(`CREATE TABLE IF NOT EXISTS content_migrations (
    version VARCHAR(100) PRIMARY KEY, source_sha256 CHAR(64) NOT NULL,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
  await pool.query(`CREATE TABLE IF NOT EXISTS content_migration_backups (
    version VARCHAR(100) NOT NULL, table_name VARCHAR(100) NOT NULL,
    rows_json LONGTEXT NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (version, table_name)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);
  const connection = await pool.getConnection();
  let locked = false;
  try {
    const [[lock]] = await connection.query("SELECT GET_LOCK('langlex-original-content', 60) AS acquired");
    if (Number(lock.acquired) !== 1) throw new Error('Could not lock content migration');
    locked = true;
    const [applied] = await connection.execute('SELECT version FROM content_migrations WHERE version = ?', [VERSION]);
    if (applied.length) return false;
    await connection.beginTransaction();
    const related = ['payment_orders', 'user_subscriptions', 'user_learning_setups',
      'user_content_progress', 'user_content_progress_items'];
    const backup = {};
    for (const table of [...TABLES, ...related]) {
      const [rows] = await connection.query(`SELECT * FROM \`${table}\` FOR UPDATE`);
      backup[table] = rows;
      await connection.execute(
        'INSERT INTO content_migration_backups (version, table_name, rows_json) VALUES (?, ?, ?)',
        [VERSION, table, JSON.stringify(rows)],
      );
    }
    // Resolve old plan IDs in one CASE expression; IDs overlap between catalogs.
    const oldPlans = new Map(backup.subsc_plans.map((plan) => [Number(plan.id), plan]));
    for (const table of ['payment_orders', 'user_subscriptions', 'user_learning_setups']) {
      const referenced = [...new Set(backup[table].map((row) => row.plan_id).filter((id) => id != null))];
      const mappings = referenced.map((id) => {
        const plan = oldPlans.get(Number(id));
        if (!plan) throw new Error(`Unresolved existing plan ${id} in ${table}`);
        return [Number(id), String(plan.type).toLowerCase() === 'free' ? 3 : 4];
      });
      if (mappings.length) {
        await connection.query(`UPDATE \`${table}\` SET plan_id = CASE plan_id ${mappings.map(() => 'WHEN ? THEN ?').join(' ')} ELSE plan_id END`, mappings.flat());
      }
    }
    for (const table of TABLES) {
      const { columns, rows } = catalog.tables[table];
      await connection.query(`DELETE FROM \`${table}\``);
      for (let offset = 0; offset < rows.length; offset += 100) {
        const batch = rows.slice(offset, offset + 100).map((row) => row.map((value, i) => normalizeValue(table, columns[i], value)));
        await connection.query(`INSERT INTO \`${table}\` (${columns.map((c) => `\`${c}\``).join(',')}) VALUES ?`, [batch]);
      }
      const [[result]] = await connection.query(`SELECT COUNT(*) AS count FROM \`${table}\``);
      if (Number(result.count) !== rows.length) throw new Error(`Import count mismatch: ${table}`);
    }
    // Dummy item IDs collide with real lesson IDs. Archive their progress above,
    // then start the new catalog fresh; retain daily activity history and accounts.
    await connection.query('DELETE FROM user_content_progress_items');
    await connection.query('DELETE FROM user_content_progress');
    await connection.execute('INSERT INTO content_migrations (version, source_sha256) VALUES (?, ?)', [VERSION, catalog.sourceSha256]);
    await connection.commit();
    console.log('Imported original LangLex learning catalog; previous content archived in content_migration_backups.');
    return true;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    if (locked) await connection.query("SELECT RELEASE_LOCK('langlex-original-content')");
    connection.release();
  }
}

module.exports = { importOriginalContent, loadCatalog, normalizeValue, TABLES, VERSION };
