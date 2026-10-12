// Pure projection: adding/removing catalogue items and changing access never edits earned work.
function summarize(topics, completions, hasPremium) {
  const earned = new Map(completions.map((row) => [`${row.content_type}:${row.item_id}`, row]));
  const seen = new Set();
  let completed = 0, total = 0, lockedTopics = 0, savedLocked = 0;
  const result = topics.map((topic) => {
    const accessible = !topic.premium || hasPremium;
    const items = [...new Map(topic.items.map((i) => [i.id, i])).values()];
    const done = items.filter((i) => earned.has(`${topic.content_type}:${i.id}`));
    const correct = done.filter((i) => earned.get(`${topic.content_type}:${i.id}`).best_correct === true || earned.get(`${topic.content_type}:${i.id}`).best_correct === 1).length;
    if (!accessible) { lockedTopics++; savedLocked += done.length; }
    for (const item of items) {
      const key = `${topic.content_type}:${item.id}`;
      if (accessible && !seen.has(key)) { seen.add(key); total++; if (earned.has(key)) completed++; }
    }
    return {
      content_type: topic.content_type, content_key: topic.content_key,
      title: topic.title, language: topic.language, accessible, premium: topic.premium,
      completed_items: done.length, total_items: items.length,
      percent: items.length ? Math.floor(done.length * 100 / items.length) : 0,
      status: !items.length ? 'empty' : done.length === items.length ? 'completed' : done.length ? 'in_progress' : 'not_started',
      correct_items: correct,
      last_practiced_at: done.map((i) => earned.get(`${topic.content_type}:${i.id}`).last_practiced_at).filter(Boolean).sort((a,b) => new Date(a) - new Date(b)).at(-1) || null,
    };
  });
  return {
    completed_items: completed, total_items: total,
    percent: total ? Math.floor(completed * 100 / total) : 0,
    completed_topics: result.filter((t) => t.accessible && t.status === 'completed').length,
    total_topics: result.filter((t) => t.accessible && t.total_items > 0).length,
    locked_topics: lockedTopics, saved_locked_items: savedLocked,
    topics: result,
  };
}
module.exports = { summarize };
