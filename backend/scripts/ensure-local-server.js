// Keep the development API alive independently of a Flutter/debug terminal.
const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { setTimeout: delay } = require('node:timers/promises');

const root = path.resolve(__dirname, '..');
process.chdir(root);
const env = require('../src/infrastructure/config/env');
const origin = `http://127.0.0.1:${env.port}`;
const logDirectory = path.join(root, '.local');
const logPath = path.join(logDirectory, 'backend.log');

async function ready() {
  let response;
  try {
    response = await fetch(`${origin}/health`, { signal: AbortSignal.timeout(2000) });
  } catch (error) {
    if (error.cause?.code === 'ECONNREFUSED') return false;
    throw error;
  }
  if (!response.ok || (await response.json()).status !== 'ok') {
    throw new Error(`Port ${env.port} is occupied by an unexpected service.`);
  }
  const progress = await fetch(`${origin}${env.apiPrefix}/user/learning-progress`, {
    signal: AbortSignal.timeout(2000),
  });
  if (progress.status !== 401) {
    throw new Error(`The running API returned ${progress.status} for the progress route. Restart its old backend process before continuing.`);
  }
  return true;
}

async function main() {
  if (await ready()) {
    console.log(`Local LangLex API is already ready at ${origin}${env.apiPrefix}/`);
    return;
  }
  fs.mkdirSync(logDirectory, { recursive: true });
  const output = fs.openSync(logPath, 'a');
  let child;
  try {
    child = spawn(process.execPath, [require.resolve('nodemon/bin/nodemon.js'), 'src/server.js'], {
      cwd: root,
      detached: true,
      stdio: ['ignore', output, output],
      env: { ...process.env, NODE_ENV: 'development' },
    });
  } finally {
    fs.closeSync(output);
  }
  let failure;
  child.on('error', error => { failure = error; });
  child.unref();
  for (let attempt = 0; attempt < 60; attempt++) {
    if (failure) throw failure;
    await delay(500);
    if (await ready()) {
      console.log(`Local LangLex API ready at ${origin}${env.apiPrefix}/`);
      console.log(`Development server PID: ${child.pid}. Log: ${logPath}`);
      return;
    }
  }
  throw new Error(`Local API did not become ready. Check MySQL and ${logPath}`);
}

main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
