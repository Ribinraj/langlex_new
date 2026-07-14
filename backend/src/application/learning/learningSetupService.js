const learningRepository = require('../../infrastructure/repositories/learningRepository');
const learningSetupRepository = require('../../infrastructure/repositories/learningSetupRepository');

const AGE_GROUPS = ['2-3 years', '3-4 years', '4-5 years', '5-6 years', '6+ years'];
const ACADEMIC_LEVELS = ['Playgroup', 'Nursery', 'LKG', 'UKG', 'Class 1', 'Class 2'];

const normalizeSetup = (setup) => ({
  ...setup,
  age_group: AGE_GROUPS.includes(setup.age_group) ? setup.age_group : AGE_GROUPS[1],
  level: ACADEMIC_LEVELS.includes(setup.level) ? setup.level : ACADEMIC_LEVELS[1],
});

const defaultSetup = async (user) => {
  const [languages, plans] = await Promise.all([
    learningRepository.listLanguages(),
    learningRepository.listPlans(),
  ]);

  const freePlan = plans.find((plan) => plan.type === 'free') || plans[0] || null;

  return {
    user_id: user.id,
    child_name: user.full_name,
    age_group: AGE_GROUPS[1],
    primary_language: languages[0] || 'English',
    learning_language: languages[1] || languages[0] || 'English',
    level: ACADEMIC_LEVELS[1],
    interests: [],
    daily_goal_minutes: 15,
    plan_id: freePlan?.id || null,
    is_configured: false,
  };
};

const getLearningSetup = async (user) => {
  const saved = await learningSetupRepository.findByUserId(user.id);
  if (saved) {
    return {
      ...normalizeSetup(saved),
      is_configured: true,
    };
  }

  return defaultSetup(user);
};

const saveLearningSetup = async (user, payload) => {
  const setup = await learningSetupRepository.upsert(user.id, normalizeSetup(payload));
  return {
    ...setup,
    is_configured: true,
  };
};

module.exports = {
  getLearningSetup,
  saveLearningSetup,
};
