const {
  applicationDefault,
  cert,
  getApps,
  initializeApp,
} = require('firebase-admin/app');

const env = require('../config/env');

let firebaseApp = null;
let initAttempted = false;

const normalizePrivateKey = (value) => {
  if (!value) return '';
  return value.replace(/\\n/g, '\n');
};

const getFirebaseApp = () => {
  if (firebaseApp) return firebaseApp;
  if (initAttempted) return null;

  initAttempted = true;

  if (getApps().length > 0) {
    [firebaseApp] = getApps();
    return firebaseApp;
  }

  const { projectId, clientEmail, privateKey } = env.firebase;
  const hasServiceAccount = projectId && clientEmail && privateKey;
  const hasApplicationDefault =
    process.env.GOOGLE_APPLICATION_CREDENTIALS || projectId;

  if (!hasServiceAccount && !hasApplicationDefault) {
    console.warn(
      '[Firebase] Push notifications disabled: configure FIREBASE_PROJECT_ID with service account env vars or GOOGLE_APPLICATION_CREDENTIALS.',
    );
    return null;
  }

  try {
    firebaseApp = initializeApp({
      credential: hasServiceAccount
        ? cert({
            projectId,
            clientEmail,
            privateKey: normalizePrivateKey(privateKey),
          })
        : applicationDefault(),
      projectId: projectId || undefined,
    });
    return firebaseApp;
  } catch (error) {
    console.error('[Firebase] Failed to initialize Admin SDK:', error.message);
    return null;
  }
};

module.exports = {
  getFirebaseApp,
};
