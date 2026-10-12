const subscriptions = require('../../infrastructure/repositories/paymentRepository');
const ApiError = require('../../shared/errors/apiError');
const normalizeAccess = value => ['premium','paid','1'].includes(String(value || '').trim().toLowerCase()) ? 'Premium' : String(value || '').trim().toLowerCase() === 'login' ? 'Login' : 'Free';
const hasPremium = subscription => Boolean(subscription && subscription.status === 'active' && String(subscription.type).toLowerCase() === 'premium' && new Date(subscription.started_at) <= new Date() && (!subscription.expires_at || new Date(subscription.expires_at) > new Date()));
async function accessFor(user) { return { signedIn: Boolean(user), premium: user ? hasPremium(await subscriptions.findActiveSubscriptionByUserId(user.id)) : false }; }
const canRead = (value,access) => normalizeAccess(value) === 'Premium' ? access.premium : normalizeAccess(value) === 'Login' ? access.signedIn : true;
function assertRead(value,access) { if (!canRead(value,access)) throw new ApiError(normalizeAccess(value) === 'Premium' ? 'An active Premium subscription is required.' : 'Sign in to open this activity.',access.signedIn ? 403 : 401); }
module.exports = { normalizeAccess, hasPremium, accessFor, canRead, assertRead };
