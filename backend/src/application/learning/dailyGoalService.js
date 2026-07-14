const dailyGoalRepository = require('../../infrastructure/repositories/dailyGoalRepository');
const learningSetupRepository = require('../../infrastructure/repositories/learningSetupRepository');

const getDailyGoal = async (user, activityDate = todayDate()) => {
  const safeActivityDate = normalizeDate(activityDate);
  const setup = await learningSetupRepository.findByUserId(user.id);
  const dailyGoalMinutes = Number(setup?.daily_goal_minutes || 15);
  const counts = await dailyGoalRepository.countByType({
    userId: user.id,
    activityDate: safeActivityDate,
  });

  return buildGoalSummary({
    activityDate: safeActivityDate,
    dailyGoalMinutes,
    counts,
  });
};

const recordDailyProgress = async (user, payload) => {
  const activityDate = normalizeDate(payload.activity_date);
  const activityType = payload.activity_type;
  const activityKey = payload.activity_key;
  const estimatedMinutes = Math.max(
    1,
    Math.min(Number(payload.estimated_minutes || defaultMinutes(activityType)), 15),
  );

  await dailyGoalRepository.recordEvent({
    userId: user.id,
    activityDate,
    activityType,
    activityKey,
    estimatedMinutes,
  });

  return getDailyGoal(user, activityDate);
};

const buildGoalSummary = ({ activityDate, dailyGoalMinutes, counts }) => {
  const words = countFor(counts, 'word');
  const quizzes = countFor(counts, 'quiz');
  const completedMinutes = Math.min(dailyGoalMinutes, words.minutes + quizzes.minutes);
  const targetWords = targetWordCount(dailyGoalMinutes);
  const targetQuizzes = targetQuizCount(dailyGoalMinutes);

  return {
    activity_date: activityDate,
    daily_goal_minutes: dailyGoalMinutes,
    target_words: targetWords,
    target_quizzes: targetQuizzes,
    completed_words: words.total,
    completed_quizzes: quizzes.total,
    completed_minutes: completedMinutes,
    is_complete:
      completedMinutes >= dailyGoalMinutes ||
      (words.total >= targetWords && quizzes.total >= targetQuizzes),
  };
};

const countFor = (counts, type) => {
  const row = counts.find((item) => item.activity_type === type);
  return {
    total: Number(row?.total || 0),
    minutes: Number(row?.minutes || 0),
  };
};

const targetWordCount = (minutes) => Math.max(3, Math.min(Math.ceil(minutes / 2), 30));

const targetQuizCount = (minutes) => Math.max(1, Math.min(Math.ceil(minutes / 10), 10));

const defaultMinutes = (activityType) => (activityType === 'quiz' ? 2 : 1);

const todayDate = () => new Date().toISOString().slice(0, 10);

const normalizeDate = (value) => {
  const text = value?.toString() || '';
  return /^\d{4}-\d{2}-\d{2}$/.test(text) ? text : todayDate();
};

module.exports = {
  getDailyGoal,
  recordDailyProgress,
};
