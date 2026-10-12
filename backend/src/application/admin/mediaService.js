const fs = require('node:fs/promises');
const path = require('node:path');
const { randomUUID } = require('node:crypto');
const { pool } = require('../../infrastructure/database/db');
const audit = require('./auditService');
const ApiError = require('../../shared/errors/apiError');
const directory = path.resolve(__dirname, '../../../public/media/uploads');
const allowed = new Set([
  'jpg',
  'png',
  'webp',
  'gif',
  'mp3',
  'wav',
  'ogg',
  'oga',
  'opus',
  'm4a',
  'aac',
  'flac',
]);
const upload = async (admin, buffer, name) => {
  if (!Buffer.isBuffer(buffer) || !buffer.length)
    throw new ApiError('Choose an image or audio file', 422);
  const { fileTypeFromBuffer } = await import('file-type');
  let type;
  try {
    type = await fileTypeFromBuffer(buffer);
  } catch {
    /* Invalid/truncated media. */
  }
  if (!type || !allowed.has(type.ext))
    throw new ApiError(
      'Unsupported file. Use JPG, PNG, WebP, GIF, MP3, WAV, OGG, M4A, AAC or FLAC.',
      422,
    );
  if (buffer.length > (type.mime.startsWith('image/') ? 5 : 20) * 1024 * 1024)
    throw new ApiError('Images can be up to 5 MB; audio up to 20 MB.', 413);
  let original;
  try {
    original = decodeURIComponent(name || 'upload');
  } catch {
    throw new ApiError('Invalid file name', 422);
  }
  original =
    path
      .basename(original)
      .replace(/[\x00-\x1f]/g, '')
      .slice(0, 255) || 'upload';
  const filename = `${randomUUID()}.${type.ext}`;
  await fs.mkdir(directory, { recursive: true });
  const target = path.join(directory, filename);
  await fs.writeFile(target, buffer, { flag: 'wx' });
  try {
    return await audit.mutate(
      admin,
      { action: 'upload', entity: 'media' },
      null,
      async () => {
        const [result] = await pool.execute(
          'INSERT INTO admin_media(original_name,path,mime_type,size_bytes,admin_id) VALUES(?,?,?,?,?)',
          [
            original,
            `/media/uploads/${filename}`,
            type.mime,
            buffer.length,
            admin.id,
          ],
        );
        const [[item]] = await pool.execute(
          'SELECT * FROM admin_media WHERE id=?',
          [result.insertId],
        );
        return item;
      },
    );
  } catch (error) {
    await fs.unlink(target).catch(() => {});
    throw error;
  }
};
const list = async ({ page = 1, limit = 25, search = '' }) => {
  const params = [`%${search}%`];
  const [[{ total }]] = await pool.execute(
    'SELECT COUNT(*) total FROM admin_media WHERE original_name LIKE ?',
    params,
  );
  const [items] = await pool.execute(
    `SELECT * FROM admin_media WHERE original_name LIKE ? ORDER BY id DESC LIMIT ${Number(limit)} OFFSET ${(page - 1) * limit}`,
    params,
  );
  return { items, total, page, limit };
};
module.exports = { upload, list };
