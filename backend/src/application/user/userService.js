const userRepository = require('../../infrastructure/repositories/userRepository');
const ApiError = require('../../shared/errors/apiError');

const getProfile = async (user) => {
  const freshUser = await userRepository.findById(user.id);
  if (!freshUser) {
    throw new ApiError('User not found', 404);
  }
  return freshUser;
};

const updateProfile = async (user, payload) => {
  const fullName = payload.full_name?.trim();
  if (!fullName) {
    throw new ApiError('Full name is required', 422);
  }

  const updatedUser = await userRepository.updateProfile(user.id, {
    full_name: fullName,
    email: nullable(payload.email),
    school: nullable(payload.school),
    city: nullable(payload.city),
    state: nullable(payload.state),
  });

  if (!updatedUser) {
    throw new ApiError('User not found', 404);
  }

  return updatedUser;
};

const updatePushToken = async (user, pushToken) => {
  const updatedUser = await userRepository.updatePushToken(
    user.id,
    nullable(pushToken),
  );

  if (!updatedUser) {
    throw new ApiError('User not found', 404);
  }

  return updatedUser;
};

const nullable = (value) => {
  const text = value?.trim() ?? '';
  return text || null;
};

module.exports = {
  getProfile,
  updateProfile,
  updatePushToken,
};
