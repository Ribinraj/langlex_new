const env = require('../../infrastructure/config/env');
const userRepository = require('../../infrastructure/repositories/userRepository');
const otpRepository = require('../../infrastructure/repositories/otpRepository');
const ApiError = require('../../shared/errors/apiError');
const { signToken } = require('../../shared/utils/jwt');
const { buildExpiry, generateOtp } = require('../../shared/utils/otp');

const checkUser = async (mobileNumber) => {
  const user = await userRepository.findByMobileNumber(mobileNumber);
  return { isExistingUser: Boolean(user) };
};

const register = async (payload) => {
  const existing = await userRepository.findByMobileNumber(payload.mobile_number);
  if (existing) {
    throw new ApiError('User already exists with this mobile number', 409);
  }

  const user = await userRepository.create(payload);
  const otp = await sendOtp(payload.mobile_number);

  return { user, otp_expires_at: otp.expires_at };
};

const sendOtp = async (mobileNumber) => {
  const user = await userRepository.findByMobileNumber(mobileNumber);
  if (!user) {
    throw new ApiError('User not found', 404);
  }

  const otp = generateOtp();
  const expiresAt = buildExpiry(env.otp.expiryMinutes);

  await otpRepository.create({ userId: user.id, otp, expiresAt });
  console.log(`Generated OTP: ${otp}`);

  return { expires_at: expiresAt.toISOString() };
};

const verifyOtp = async ({ mobile_number, otp, push_token }) => {
  const user = await userRepository.findByMobileNumber(mobile_number);
  if (!user) {
    throw new ApiError('User not found', 404);
  }

  const verification = await otpRepository.findLatestActive(user.id, otp);
  if (!verification) {
    throw new ApiError('Invalid OTP', 400);
  }

  if (new Date(verification.expires_at).getTime() < Date.now()) {
    throw new ApiError('OTP has expired', 400);
  }

  await otpRepository.markVerified(verification.id);
  const updatedUser = await userRepository.updatePushToken(user.id, push_token);
  const token = signToken(updatedUser);

  return { token, user: updatedUser };
};

const logout = async (userId) => {
  await userRepository.clearPushToken(userId);
};

module.exports = {
  checkUser,
  register,
  sendOtp,
  verifyOtp,
  logout,
};
