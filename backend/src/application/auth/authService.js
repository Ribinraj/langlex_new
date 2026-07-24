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

  return {
    user,
    otp_expires_at: otp.expires_at,
    resend_after_seconds: otp.resend_after_seconds,
  };
};

const sendOtp = async (mobileNumber) => {
  return generateAndStoreOtp(mobileNumber);
};

const resendOtp = async (mobileNumber) => {
  const user = await userRepository.findByMobileNumber(mobileNumber);
  if (!user) {
    throw new ApiError('User not found', 404);
  }

  const latestOtp = await otpRepository.findLatestByUser(user.id);
  const resendAfterSeconds = secondsUntilResendAvailable(latestOtp);

  if (resendAfterSeconds > 0) {
    throw new ApiError(
      `Please wait ${resendAfterSeconds} seconds before requesting another OTP`,
      429,
      { resend_after_seconds: resendAfterSeconds },
    );
  }

  return createOtpForUser(user);
};

const generateAndStoreOtp = async (mobileNumber) => {
  const user = await userRepository.findByMobileNumber(mobileNumber);
  if (!user) {
    throw new ApiError('User not found', 404);
  }

  return createOtpForUser(user);
};

const createOtpForUser = async (user) => {
  const otp = generateOtp();
  const expiresAt = buildExpiry(env.otp.expiryMinutes);

  await otpRepository.create({ userId: user.id, otp, expiresAt });
  console.log(`Generated OTP: ${otp}`);

  return {
    expires_at: expiresAt.toISOString(),
    resend_after_seconds: env.otp.resendCooldownSeconds,
  };
};

const secondsUntilResendAvailable = (latestOtp) => {
  if (!latestOtp) return 0;

  const createdAt = new Date(latestOtp.created_at).getTime();
  if (Number.isNaN(createdAt)) return 0;

  const availableAt = createdAt + env.otp.resendCooldownSeconds * 1000;
  const remainingMs = availableAt - Date.now();
  return remainingMs > 0 ? Math.ceil(remainingMs / 1000) : 0;
};

const verifyOtp = async ({ mobile_number, otp, push_token }) => {
  const user = await userRepository.findByMobileNumber(mobile_number);
  if (!user) {
    throw new ApiError('User not found', 404);
  }

  const isFixedOtp = isFixedTestOtp({ mobileNumber: mobile_number, otp });

  if (!isFixedOtp) {
    const verification = await otpRepository.findLatestActive(user.id, otp);
    if (!verification) {
      throw new ApiError('Invalid OTP', 400);
    }

    if (new Date(verification.expires_at).getTime() < Date.now()) {
      throw new ApiError('OTP has expired', 400);
    }

    await otpRepository.markVerified(verification.id);
  }

  const updatedUser = await userRepository.updatePushToken(user.id, push_token);
  const token = signToken(updatedUser);

  return { token, user: updatedUser };
};

const isFixedTestOtp = ({ mobileNumber, otp }) => {
  return (
    env.nodeEnv !== 'production' &&
    mobileNumber === env.otp.fixedMobileNumber &&
    otp === env.otp.fixedCode
  );
};

const logout = async (userId) => {
  await userRepository.clearPushToken(userId);
};

module.exports = {
  checkUser,
  register,
  sendOtp,
  resendOtp,
  verifyOtp,
  logout,
};
