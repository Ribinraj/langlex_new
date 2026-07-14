const authService = require('../../../application/auth/authService');

const checkUser = async (req, res) => {
  const result = await authService.checkUser(req.body.mobile_number);
  res.json(result);
};

const register = async (req, res) => {
  const result = await authService.register(req.body);
  res.status(201).json({
    message: 'Registration successful. OTP generated.',
    ...result,
  });
};

const sendOtp = async (req, res) => {
  const result = await authService.sendOtp(req.body.mobile_number);
  res.json({
    message: 'OTP generated successfully',
    ...result,
  });
};

const verifyOtp = async (req, res) => {
  const result = await authService.verifyOtp(req.body);
  res.json(result);
};

const logout = async (req, res) => {
  await authService.logout(req.user.id);
  res.json({ message: 'Logged out successfully' });
};

module.exports = {
  checkUser,
  register,
  sendOtp,
  verifyOtp,
  logout,
};
