const assertAccountAccess = require('./accountAccess');
const env = require('../../infrastructure/config/env');
const userRepository = require('../../infrastructure/repositories/userRepository');
const userAuthIdentityRepository = require('../../infrastructure/repositories/userAuthIdentityRepository');
const otpRepository = require('../../infrastructure/repositories/otpRepository');
const { getFirebaseApp } = require('../../infrastructure/firebase/firebaseAdmin');
const ApiError = require('../../shared/errors/apiError');
const { signToken } = require('../../shared/utils/jwt');
const { buildExpiry, generateOtp } = require('../../shared/utils/otp');
const { getAuth } = require('firebase-admin/auth');

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
    ...otp,
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

  assertAccountAccess(user);
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
  assertAccountAccess(user);
  const otp = getOtpForUser(user);
  const expiresAt = buildExpiry(env.otp.expiryMinutes);

  await otpRepository.create({ userId: user.id, otp, expiresAt });


  return {
    ...(env.otp.exposeCode ? { display_otp: otp } : {}),
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

  assertAccountAccess(user);
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

  await userRepository.markMobileVerified(user.id);
  const updatedUser = await userRepository.updatePushToken(user.id, push_token);
  const token = signToken(updatedUser);

  return { token, user: updatedUser };
};

const socialLogin = async ({ id_token, push_token }) => {
  const identity = await buildFirebaseIdentity(id_token);
  debugGoogleAuth('Verified Firebase identity', identity);
  const linkedIdentity = await userAuthIdentityRepository.findByProviderUid({
    provider: identity.provider,
    providerUid: identity.providerUid,
  });

  if (!linkedIdentity) {
    debugGoogleAuth('Backend social-login result', {
      requires_registration: true,
      provider: identity.provider,
      email: identity.email,
    });
    return {
      requires_registration: true,
      provider: identity.provider,
      email: identity.email,
      full_name: identity.fullName,
    };
  }

  const user = await userRepository.findById(linkedIdentity.user_id);
  if (!user) {
    throw new ApiError('Linked user account was not found', 404);
  }

  assertAccountAccess(user);
  if (!user.mobile_verified_at) {
    const otp = await createOtpForUser(user);
    debugGoogleAuth('Backend social-login result', {
      requires_mobile_verification: true,
      user_id: user.id,
      mobile_number: user.mobile_number,
    });
    return {
      requires_mobile_verification: true,
      mobile_number: user.mobile_number,
      ...otp,
      resend_after_seconds: otp.resend_after_seconds,
    };
  }

  const updatedUser = await userRepository.updatePushToken(user.id, push_token);
  const token = signToken(updatedUser);
  debugGoogleAuth('Backend social-login result', {
    authenticated: true,
    user_id: updatedUser.id,
    email: updatedUser.email,
  });
  return { token, user: updatedUser };
};

const socialRegister = async (payload) => {
  const identity = await buildFirebaseIdentity(payload.id_token);
  debugGoogleAuth('Verified Firebase identity for registration', identity);
  const existingIdentity = await userAuthIdentityRepository.findByProviderUid({
    provider: identity.provider,
    providerUid: identity.providerUid,
  });
  if (existingIdentity) {
    throw new ApiError('This social account is already registered', 409);
  }

  const existingMobileUser = await userRepository.findByMobileNumber(
    payload.mobile_number,
  );
  if (existingMobileUser) {
    throw new ApiError(
      'This mobile number is already registered. Please log in with OTP first.',
      409,
    );
  }

  const user = await userRepository.create({
    mobile_number: payload.mobile_number,
    full_name: payload.full_name || identity.fullName,
    email: payload.email || identity.email,
    school: payload.school,
    city: payload.city,
    state: payload.state,
  });

  await userAuthIdentityRepository.create({
    userId: user.id,
    provider: identity.provider,
    providerUid: identity.providerUid,
    email: identity.email,
    emailVerified: identity.emailVerified,
  });

  const otp = await createOtpForUser(user);
  debugGoogleAuth('Backend social-register result', {
    user_id: user.id,
    provider: identity.provider,
    mobile_number: user.mobile_number,
  });
  return {
    user,
    ...otp,
    otp_expires_at: otp.expires_at,
    resend_after_seconds: otp.resend_after_seconds,
  };
};

const buildFirebaseIdentity = async (idToken) => {
  const decodedToken = await verifyFirebaseIdToken(idToken);
  const provider = providerFromToken(decodedToken);
  const fullName = normalizeText(decodedToken.name) || 'LangLex Learner';
  const email = normalizeText(decodedToken.email);

  return {
    provider,
    providerUid: decodedToken.uid,
    email,
    emailVerified: decodedToken.email_verified === true,
    fullName,
  };
};

const verifyFirebaseIdToken = async (idToken) => {
  const app = getFirebaseApp();
  if (!app) {
    throw new ApiError('Firebase authentication is not configured', 503);
  }

  try {
    return await getAuth(app).verifyIdToken(idToken);
  } catch (_) {
    throw new ApiError('Invalid Firebase login token', 401);
  }
};

const providerFromToken = (decodedToken) => {
  const firebaseProvider = decodedToken.firebase?.sign_in_provider || '';
  if (firebaseProvider === 'google.com') return 'google';
  if (firebaseProvider === 'apple.com') return 'apple';
  throw new ApiError('Only Google and Apple login are supported here', 400);
};

const normalizeText = (value) => {
  const text = value?.toString().trim() || '';
  return text || null;
};

const debugGoogleAuth = (label, payload) => {
  if (env.nodeEnv === 'production') return;
  const sanitized = { ...payload };
  if (sanitized.providerUid) {
    sanitized.providerUid = maskValue(sanitized.providerUid);
  }
  console.log(`[GoogleAuth] ${label}:`, sanitized);
};

const maskValue = (value) => {
  const text = value?.toString() || '';
  if (text.length <= 8) return '***';
  return `${text.slice(0, 4)}...${text.slice(-4)}`;
};

const isFixedTestOtp = ({ mobileNumber, otp }) => {
  return (
    env.nodeEnv !== 'production' &&
    isFixedOtpMobile(mobileNumber) &&
    otp === env.otp.fixedCode
  );
};

const getOtpForUser = (user) => {
  return isFixedOtpMobile(user.mobile_number) ? env.otp.fixedCode : generateOtp();
};

const isFixedOtpMobile = (mobileNumber) => {
  return Boolean(
    env.otp.fixedMobileNumber &&
      env.otp.fixedCode &&
      mobileNumber === env.otp.fixedMobileNumber,
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
  socialLogin,
  socialRegister,
  logout,
};
