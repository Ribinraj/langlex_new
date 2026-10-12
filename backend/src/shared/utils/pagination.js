const ApiError = require('../errors/apiError');
function pagination(query = {}) {
  const integer = (value, fallback, max, name) => {
    if (value === undefined) return fallback;
    if (typeof value !== 'string' && typeof value !== 'number') throw new ApiError(`Invalid ${name}`, 400);
    if (!/^\d+$/.test(String(value)) || !Number.isSafeInteger(Number(value)) || Number(value) < 1 || Number(value) > max) {
      throw new ApiError(`${name} must be an integer from 1 to ${max}`, 400);
    }
    return Number(value);
  };
  const page = integer(query.page, 1, 1000000, 'page');
  const limit = integer(query.limit, 20, 100, 'limit');
  return { page, limit, offset: (page - 1) * limit };
}
function pageResult(items, total, { page, limit }) {
  total = Number(total);
  return { items, pagination: { page, limit, total, total_pages: Math.ceil(total / limit), has_more: page * limit < total } };
}
function textFilter(value, name) {
  if (value === undefined || value === '') return '';
  if (typeof value !== 'string' || value.length > 255) throw new ApiError(`Invalid ${name}`, 400);
  return value.trim();
}
module.exports = { pagination, pageResult, textFilter };
