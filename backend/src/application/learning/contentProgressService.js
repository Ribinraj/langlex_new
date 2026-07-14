const contentProgressRepository = require('../../infrastructure/repositories/contentProgressRepository');

const getProgress = async (user, query) => {
  return buildResponse({
    userId: user.id,
    contentType: query.content_type,
    contentKey: query.content_key,
  });
};

const recordItemProgress = async (user, payload) => {
  const status = payload.status || 'in_progress';
  const totalItems = Number(payload.total_items || 0);
  const position = Number(payload.position || 0);

  await contentProgressRepository.recordItem({
    userId: user.id,
    contentType: payload.content_type,
    contentKey: payload.content_key,
    itemKey: payload.item_key,
    position,
    isCorrect: payload.is_correct == null ? null : Boolean(payload.is_correct),
  });

  const items = await contentProgressRepository.listItems({
    userId: user.id,
    contentType: payload.content_type,
    contentKey: payload.content_key,
  });
  const score = items.filter((item) => item.is_correct === true).length;

  await contentProgressRepository.upsertProgress({
    userId: user.id,
    contentType: payload.content_type,
    contentKey: payload.content_key,
    status,
    position,
    totalItems,
    score,
    metadata: payload.metadata || null,
  });

  return buildResponse({
    userId: user.id,
    contentType: payload.content_type,
    contentKey: payload.content_key,
  });
};

const saveProgress = async (user, payload) => {
  await contentProgressRepository.upsertProgress({
    userId: user.id,
    contentType: payload.content_type,
    contentKey: payload.content_key,
    status: payload.status || 'in_progress',
    position: Number(payload.position || 0),
    totalItems: Number(payload.total_items || 0),
    score: Number(payload.score || 0),
    metadata: payload.metadata || null,
  });

  return buildResponse({
    userId: user.id,
    contentType: payload.content_type,
    contentKey: payload.content_key,
  });
};

const restartSession = async (user, payload) => {
  await contentProgressRepository.restartSession({
    userId: user.id,
    contentType: payload.content_type,
    contentKey: payload.content_key,
  });

  return buildResponse({
    userId: user.id,
    contentType: payload.content_type,
    contentKey: payload.content_key,
  });
};

const buildResponse = async ({ userId, contentType, contentKey }) => {
  const [progress, items] = await Promise.all([
    contentProgressRepository.findProgress({ userId, contentType, contentKey }),
    contentProgressRepository.listItems({ userId, contentType, contentKey }),
  ]);

  return {
    content_type: contentType,
    content_key: contentKey,
    status: progress?.status || 'not_started',
    position: progress?.position || 0,
    total_items: progress?.total_items || 0,
    score: progress?.score || 0,
    metadata: progress?.metadata || {},
    last_practiced_at: progress?.last_practiced_at || null,
    completed_at: progress?.completed_at || null,
    completed_item_keys: items.map((item) => item.item_key),
    items,
  };
};

module.exports = {
  getProgress,
  recordItemProgress,
  saveProgress,
  restartSession,
};
