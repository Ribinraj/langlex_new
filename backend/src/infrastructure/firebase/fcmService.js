const { getMessaging } = require('firebase-admin/messaging');

const { getFirebaseApp } = require('./firebaseAdmin');

const invalidTokenCodes = new Set([
  'messaging/invalid-argument',
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

const toFcmData = (data = {}) => {
  return Object.entries(data || {}).reduce((result, [key, value]) => {
    if (value === undefined || value === null) return result;
    result[key] = typeof value === 'string' ? value : JSON.stringify(value);
    return result;
  }, {});
};

const sendToTokens = async ({ tokens, title, body, data = {} }) => {
  const uniqueTokens = [...new Set(tokens.filter(Boolean))];
  const result = {
    enabled: false,
    requested: uniqueTokens.length,
    success: 0,
    failure: 0,
    invalidTokens: [],
    errors: [],
  };

  if (uniqueTokens.length === 0) return result;

  const firebaseApp = getFirebaseApp();
  if (!firebaseApp) {
    result.errors.push('Firebase Admin SDK is not configured.');
    return result;
  }

  result.enabled = true;

  try {
    const response = await getMessaging(firebaseApp).sendEachForMulticast({
      tokens: uniqueTokens,
      notification: { title, body },
      data: toFcmData(data),
      android: {
        priority: 'high',
        notification: {
          channelId: 'langlex_notifications',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    result.success = response.successCount;
    result.failure = response.failureCount;
    response.responses.forEach((item, index) => {
      if (item.success) return;
      const code = item.error?.code || 'messaging/unknown';
      result.errors.push(code);
      if (invalidTokenCodes.has(code)) {
        result.invalidTokens.push(uniqueTokens[index]);
      }
    });
  } catch (error) {
    result.failure = uniqueTokens.length;
    result.errors.push(error.code || error.message || 'messaging/unknown');
  }

  return result;
};

module.exports = {
  sendToTokens,
};
