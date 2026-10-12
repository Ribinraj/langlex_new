# LangLex Admin Panel

React + Vite administrator dashboard for LangLex.

## Stack

- React 19
- Vite
- React Router
- Redux Toolkit
- Axios
- Material UI
- React Hook Form + Zod
- Recharts

## Setup

```bash
cd adminpanel
cp .env.example .env
npm install
npm run dev
```

The app expects the backend at:

```text
VITE_API_BASE_URL=http://127.0.0.1:5050/api
```

Default local admin credentials are seeded by the backend on startup:

```text
crisanttechnologies@gmail.com
M@njula1105
```

Change `ADMIN_EMAIL`, `ADMIN_PASSWORD`, and `ADMIN_NAME` in the backend environment before first production startup.

## Scripts

```bash
npm run dev
npm run build
npm run lint
npm run preview
```

## Learning content workflow

Open `/learning` and choose Knowledge, Alphabets, Stories or Quizzes. Knowledge
also contains Sounds. Filter topics by language or standard; open a topic to
manage its words, examples, passages or questions. Add topic and Edit topic let
you assign multiple standards or All standards. New items inherit the topic's
standards. Existing individual assignments are retained unless you explicitly
apply the topic's standards to every item. Needs review flags unrecognized
original assignments. Student preview shows the content assigned to the chosen
language and standard; access labels identify Premium topics separately.

Import / bulk edit is available inside each topic. CSV imports inherit that
topic's language and standards; edits retain individual standard assignments.
Review the validated preview before applying a batch (up to 100 items).

Subscription plans are under Settings → Manage subscription plans. Development
runs default to `http://127.0.0.1:5050/api`; production builds retain the hosted
API unless `VITE_API_BASE_URL` overrides it. Run the local backend before opening
the admin workspace. This local redesign has not been deployed.
