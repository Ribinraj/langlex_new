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
