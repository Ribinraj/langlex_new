// Adapt legacy rows for the mobile catalog while retaining original rows in MySQL.
const key = (value) => String(value || '').trim().toLowerCase();
const groupKey = (row) => JSON.stringify([key(row.language), key(row.title), key(row.grade)]);

function groupStoryPassages(rows) {
  const groups = new Map();
  for (const row of rows) {
    const id = groupKey(row);
    if (!groups.has(id)) groups.set(id, { ...row, sections: [] });
    const story = groups.get(id);
    story.sections.push({ id: row.id, text: row.text, image: row.image, audio: row.audio,
      audio_text_map: row.audio_text_map });
    if (['premium', 'paid', '1'].includes(key(row.show_plan))) story.show_plan = 'Premium';
    else if (key(row.show_plan) === 'login' && !['premium','paid','1'].includes(key(story.show_plan))) story.show_plan = 'Login';
  }
  return [...groups.values()].map((story) => ({ ...story,
    text: story.sections.map((section) => section.text).join('\n\n'),
  }));
}

function addMissingCourses(courses, content) {
  const result = [...courses];
  const known = new Set(courses.map((row) => JSON.stringify([key(row.language), key(row.title)])));
  const groups = new Map();
  for (const row of content) {
    const id = JSON.stringify([key(row.language), key(row.course)]);
    if (!row.course || key(row.course) === 'skip' || known.has(id)) continue;
    if (!groups.has(id)) {
      groups.set(id, { id: 1000000 + Number(row.id), title: row.course,
        created: row.created, image: row.content_image, language: row.language,
        show_plan: '', level: '' });
    }
  }
  return [...result, ...groups.values()];
}
module.exports = { groupStoryPassages, addMissingCourses };
