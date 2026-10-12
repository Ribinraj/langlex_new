const crypto = require('crypto');
const { pool } = require('../../infrastructure/database/db');
const repository = require('../../infrastructure/repositories/learningProgressRepository');
const catalog = require('../../infrastructure/repositories/progressCatalogRepository');
const setups = require('../../infrastructure/repositories/learningSetupRepository');
const subscriptions = require('../../infrastructure/repositories/paymentRepository');
const { summarize } = require('./progressSummary');
const ApiError = require('../../shared/errors/apiError');

const prefix = (type) => type === 'course' ? 'content' : type;
const itemKey = (topic, item) => `${prefix(topic.content_type)}-${item.id}`;
async function context(user) {
  const [setup, subscription] = await Promise.all([setups.findByUserId(user.id), subscriptions.findActiveSubscriptionByUserId(user.id)]);
  const languages = setup?.selected_languages || [];
  if (!languages.length) throw new ApiError('Choose your learning languages first.', 409);
  // A setup's plan_id is a preference, never proof of purchase.
  const hasPremium = require('./contentAccess').hasPremium(subscription);
  return { setup, subscription, languages, hasPremium };
}
async function resolve(user, payload) {
  const access = await context(user);
  const topic = await catalog.resolve(payload.content_type, payload.content_key, access.languages,pool,access.hasPremium,access.setup.level);
  if (!topic) throw new ApiError('This activity is no longer available in your selected languages.', 404);
  return { ...access, topic };
}
async function response(userId, topic, executor = pool) {
  const current = await repository.session(userId, topic.content_type, topic.content_key, executor);
  const valid = new Set(topic.items.map((i) => itemKey(topic,i)));
  const items = current.items.filter((i) => valid.has(i.item_key));
  const complete = topic.items.length > 0 && items.length === topic.items.length;
  return {
    content_type: topic.content_type, content_key: topic.content_key,
    status: complete ? 'completed' : items.length ? 'in_progress' : 'not_started',
    position: Math.min(Number(current.position || 0), Math.max(0, topic.items.length - 1)),
    total_items: topic.items.length, score: items.filter((i) => Boolean(i.is_correct)).length,
    metadata: { ...current.metadata, session_id: current.metadata.session_id || 'legacy' },
    last_practiced_at: current.last_practiced_at || null,
    completed_at: complete ? current.completed_at : null,
    completed_item_keys: items.map((i) => i.item_key), items,
  };
}
async function getProgress(user, query) {
  const { topic } = await resolve(user, query);
  return response(user.id, topic);
}
async function mutate(user, payload, mode) {
  const { topic, hasPremium } = await resolve(user, payload);
  return repository.transaction(user.id, async (connection) => {
    if (!await repository.claimEvent(user.id, payload.event_id, connection)) return response(user.id,topic,connection);
    if (topic.premium && !hasPremium) throw new ApiError('An active Premium plan is required for this activity.', 403);
    const current = await repository.session(user.id,topic.content_type,topic.content_key,connection);
    if (mode === 'restart') {
      await connection.execute('DELETE FROM user_content_progress_items WHERE user_id=? AND content_type=? AND content_key=?', [user.id,topic.content_type,topic.content_key]);
      await repository.save(user.id,topic,0,'not_started',0,{session_id: payload.next_session_id || crypto.randomUUID()},connection);
      return response(user.id,topic,connection);
    }
    const sessionId = current.metadata.session_id || 'legacy';
    const staleSession = payload.session_id && payload.session_id !== sessionId;
    let selected = [];
    if (mode === 'item') {
      selected = topic.items.filter((i) => itemKey(topic,i) === payload.item_key);
      if (!selected.length) throw new ApiError('This item does not belong to the activity.',400);
    } else if (payload.status === 'completed' && topic.content_type === 'story') {
      selected = topic.items;
    }
    for (const item of selected) {
      const position = topic.items.findIndex((i) => i.id === item.id);
      let correct = null;
      if (topic.content_type === 'quiz') {
        if (payload.answer == null && payload.event_id) throw new ApiError('A quiz answer is required.',400);
        // Older installed clients sent only is_correct. Preserve their answered
        // step, but do not treat an unverified client boolean as accuracy.
        correct = payload.answer == null ? null : String(payload.answer).trim() === String(item.answer).trim();
      }
      await repository.earn(user.id,topic.content_type,item.id,correct,connection);
      if (!staleSession) await repository.record(user.id,topic.content_type,topic.content_key,itemKey(topic,item),position,correct,connection);
    }
    const updated = await response(user.id,topic,connection);
    const requestedItem = selected.at(-1);
    const position = requestedItem ? topic.items.findIndex((i) => i.id === requestedItem.id) : updated.position;
    if (!staleSession) await repository.save(user.id,topic,position,updated.status,updated.score,{session_id:sessionId},connection);
    return response(user.id,topic,connection);
  });
}
async function overview(user, query = {}) {
  const { setup, subscription, languages, hasPremium } = await context(user);
  const language = query.language || setup.learning_language;
  if (!languages.includes(language)) throw new ApiError('Choose one of your selected languages.',403);
  const [topics, earned] = await Promise.all([catalog.topics(language, setup.level),repository.completions(user.id)]);
  return {
    language, level: setup.level, selected_languages: languages,
    has_premium: hasPremium, plan_name: hasPremium ? subscription.plan_name : 'Free',
    expires_at: hasPremium ? subscription.expires_at : null,
    ...summarize(topics,earned,hasPremium),
  };
}
module.exports = { getProgress, overview,
  recordItemProgress: (user,payload) => mutate(user,payload,'item'),
  saveProgress: (user,payload) => mutate(user,payload,'save'),
  restartSession: (user,payload) => mutate(user,payload,'restart'),
};
