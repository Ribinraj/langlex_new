const generateOtp = () => {
  return String(Math.floor(100000 + Math.random() * 900000));
};

const buildExpiry = (minutes) => {
  const expiresAt = new Date();
  expiresAt.setMinutes(expiresAt.getMinutes() + minutes);
  return expiresAt;
};

module.exports = {
  generateOtp,
  buildExpiry,
};
