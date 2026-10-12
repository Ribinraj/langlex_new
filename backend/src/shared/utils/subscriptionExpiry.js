function buildExpiry(startedAt, period = '') {
  const normalized = period.trim().toLowerCase();
  const expiresAt = new Date(startedAt);
  if (normalized === 'monthly' || normalized === 'yearly' || normalized === 'annual') {
    const day = expiresAt.getUTCDate();
    expiresAt.setUTCDate(1);
    expiresAt.setUTCMonth(expiresAt.getUTCMonth() + (normalized === 'monthly' ? 1 : 12));
    const lastDay = new Date(Date.UTC(expiresAt.getUTCFullYear(), expiresAt.getUTCMonth() + 1, 0)).getUTCDate();
    expiresAt.setUTCDate(Math.min(day, lastDay));
    return expiresAt;
  }
  const match = normalized.match(/(\d+)/);
  if (!match || Number(match[1]) <= 0) return null;
  expiresAt.setUTCDate(expiresAt.getUTCDate() + Number(match[1]));
  return expiresAt;
}
module.exports = { buildExpiry };
