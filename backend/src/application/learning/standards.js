const standards = ['Playgroup', 'Nursery', 'LKG', 'UKG', 'Class 1', 'Class 2'];
const aliases = {
  Nursery: ['Nursery', 'शिशुसदन', 'ಶಿಶುವಿಹಾರ', 'নাৰ্চাৰী', 'beginner'],
  LKG: [
    'LKG',
    'अवर बालविहार',
    'अवर शिशुविहार',
    'ಎಲ್ಕೆಜಿ',
    'এলকেজি',
    'intermediate',
  ],
  UKG: ['UKG', 'बालविहार', 'शिशुविहार', 'ಯುಕೆಜಿ', 'ইউকেজি', 'advanced'],
};
function normalize(value) {
  const text = String(value || '')
    .trim()
    .toLowerCase();
  return (
    standards.find((s) =>
      (aliases[s] || [s]).some((v) => v.toLowerCase() === text),
    ) || null
  );
}
const parse = (value) =>
  typeof value === 'string' ? JSON.parse(value) : value;
const matches = (assigned, level) =>
  !level ||
  (assigned || []).includes('*') ||
  (assigned || []).includes(normalize(level) || level);
function validate(value) {
  if (
    !Array.isArray(value) ||
    !value.length ||
    new Set(value).size !== value.length ||
    value.some((s) => s !== '*' && !standards.includes(s)) ||
    (value.includes('*') && value.length !== 1)
  ) {
    throw new (require('../../shared/errors/apiError'))(
      'Select at least one standard, or All standards.',
      422,
    );
  }
  return value;
}
module.exports = { standards, aliases, normalize, matches, parse, validate };
