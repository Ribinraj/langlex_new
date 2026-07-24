const jwt = require('jsonwebtoken');

const adminRepository = require('../../infrastructure/repositories/adminRepository');
const env = require('../../infrastructure/config/env');
const ApiError = require('../../shared/errors/apiError');
const { comparePassword } = require('../../shared/utils/password');

const login = async ({ email, password }) => {
  const admin = await adminRepository.findAdminByEmail(email);
  if (!admin || !admin.is_active) {
    throw new ApiError('Invalid admin credentials', 401);
  }

  const matches = await comparePassword(password, admin.password_hash);
  if (!matches) {
    throw new ApiError('Invalid admin credentials', 401);
  }

  const updatedAdmin = await adminRepository.updateAdminLogin(admin.id);
  return {
    token: signAdminToken(updatedAdmin),
    admin: updatedAdmin,
  };
};

const getCurrentAdmin = async (adminId) => {
  const admin = await adminRepository.findAdminById(adminId);
  if (!admin || !admin.is_active) {
    throw new ApiError('Admin account is not active', 401);
  }
  return admin;
};

const signAdminToken = (admin) =>
  jwt.sign(
    {
      sub: String(admin.id),
      type: 'admin',
      role: admin.role,
      email: admin.email,
    },
    env.jwt.secret,
    { expiresIn: env.jwt.expiresIn },
  );

module.exports = {
  login,
  getCurrentAdmin,
};
