const ApiError = require('../../shared/errors/apiError');

const resolveLanguages = (existing, payload, supported) => {
  const saved = existing?.selected_languages || [];
  const chosen = payload.selected_languages || saved;
  if (chosen.length !== 3 || new Set(chosen).size !== 3 ||
      chosen.some((language) => !supported.includes(language))) {
    throw new ApiError('Choose exactly three different supported languages.', 400);
  }
  if (saved.length === 3 && (chosen.length !== saved.length ||
      chosen.some((language) => !saved.includes(language)))) {
    throw new ApiError('Your three selected languages cannot be replaced.', 409);
  }
  const active = payload.active_language || payload.learning_language ||
    existing?.learning_language || chosen[0];
  if (!chosen.includes(active)) {
    throw new ApiError('Choose one of your three selected languages.', 400);
  }
  return { selected_languages: saved.length === 3 ? saved : chosen,
    active_language: active, primary_language: active, learning_language: active };
};
module.exports = { resolveLanguages };
