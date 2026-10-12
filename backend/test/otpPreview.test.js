const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const mock = (file, exports) => { const id = require.resolve(file); require.cache[id] = {id, filename:id, loaded:true, exports}; };
const env = {nodeEnv: 'production', otp: {exposeCode: true, expiryMinutes: 5, resendCooldownSeconds: 30}};
let record;
const user = {id: 123, mobile_number: '9000000001'};
mock('../src/infrastructure/config/env', env);
mock('../src/infrastructure/repositories/userRepository', {
  findByMobileNumber: async () => user, markMobileVerified: async () => {}, updatePushToken: async () => user,
});
mock('../src/infrastructure/repositories/otpRepository', {
  create: async data => { record = {...data, id: 1}; },
  findLatestByUser: async () => ({created_at: new Date()}),
  findLatestActive: async (_id, code) => record?.otp === code ? record : null,
  markVerified: async () => {record = null;},
});
mock('../src/infrastructure/repositories/userAuthIdentityRepository', {});
mock('../src/infrastructure/firebase/firebaseAdmin', {});
mock('../src/shared/utils/jwt', {signToken: () => 'test-session'});
const auth = require('../src/application/auth/authService');
test('preview returns actual stored code; verification still rejects wrong codes', async () => {
  const challenge = await auth.sendOtp(user.mobile_number);
  assert.match(challenge.display_otp, /^\d{6}$/);
  assert.equal(challenge.display_otp, record.otp);
  assert.equal(challenge.resend_after_seconds, 30);
  assert.ok(Date.parse(challenge.expires_at) > Date.now());
  record.expires_at = record.expiresAt;
  await assert.rejects(auth.verifyOtp({mobile_number: user.mobile_number, otp: 'wrong'}), /Invalid OTP/);
  const result = await auth.verifyOtp({mobile_number: user.mobile_number, otp: challenge.display_otp});
  assert.equal(result.token, 'test-session');
  await assert.rejects(auth.verifyOtp({mobile_number: user.mobile_number, otp: challenge.display_otp}), /Invalid OTP/);
});
test('preview is disabled by configuration and resend cooldown remains enforced', async () => {
  env.otp.exposeCode = false;
  assert.equal((await auth.sendOtp(user.mobile_number)).display_otp, undefined);
  await assert.rejects(auth.resendOtp(user.mobile_number), /Please wait/);
});
test('expired codes cannot authenticate', async () => {
  env.otp.exposeCode = true;
  const challenge = await auth.sendOtp(user.mobile_number);
  record.expires_at = new Date(Date.now() - 1000);
  await assert.rejects(auth.verifyOtp({mobile_number: user.mobile_number, otp: challenge.display_otp}), /expired/);
});
