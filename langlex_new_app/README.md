# LangLex Flutter app

## Run against the local backend

Start the API in a separate terminal from the repository root:

```sh
cd backend
npm run dev:ensure
```

`dev:ensure` starts a persistent development server or reuses the running one.
Logs are in `backend/.local/backend.log`. The local VS Code launch configurations
run this command automatically before starting Flutter.

The backend uses `backend/.env` and initializes the configured local MySQL database,
including the progress migration, before listening on port 5050.

From `langlex_new_app`, run the iOS simulator app with:

```sh
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5050/api/
```

For an Android emulator use `http://10.0.2.2:5050/api/`. A physical device needs
the Mac's reachable LAN address instead of localhost and must share its network.

VS Code launch configurations are included in `.vscode/launch.json` in both the
repository root and Flutter app folder. Choose
**LangLex - Local API (iOS simulator)** or **LangLex - Local API (Android emulator)**.
Stop and relaunch when changing API environments; hot reload does not change
compile-time `--dart-define` values. Local and hosted databases have separate
accounts/sessions, so signing in again may be necessary after switching.

## Check the local API

```sh
curl http://127.0.0.1:5050/health
curl -i 'http://127.0.0.1:5050/api/user/learning-progress?language=English'
```

Health returns 200. The unauthenticated progress request should return 401,
confirming the route is registered and requires login. A signed-in user with a
learning setup receives their progress with 200. A 404 means the running server
has not loaded the updated route.

All builds default to `https://langlex.crisant.com/api/`. For local development,
pass `--dart-define=API_BASE_URL=http://127.0.0.1:5050/api/` for the iOS
simulator/desktop/web, or use `http://10.0.2.2:5050/api/` for the Android emulator.
