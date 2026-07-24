# LangLex Backend

Express + MySQL backend for LangLex authentication and learning content APIs.

## Architecture

The runtime code lives in `src/` using a clean layered structure:

```text
src/
  app.js                         # Express composition root
  server.js                      # Startup/bootstrap entrypoint
  application/                   # Use cases and business flow
    auth/authService.js
    learning/learningService.js
    payment/paymentService.js
  infrastructure/                # Framework/database/config implementations
    config/env.js
    database/db.js
    database/initDatabase.js
    repositories/
  interfaces/http/               # HTTP adapters only
    controllers/
    middleware/
    routes/
  shared/                        # Shared errors and utilities
    errors/
    utils/
```

Request flow:

```text
HTTP route -> controller -> application service -> repository -> MySQL
```

Root `app.js` and `server.js` are only compatibility wrappers; `npm start` and `npm run dev` run `src/server.js`.

## Setup

1. Create the database and tables manually if needed:

   ```bash
   mysql -u root -p < database/schema.sql
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Update `.env` with your MySQL credentials and a strong `JWT_SECRET`.

4. Start the API:

   ```bash
   npm run dev
   ```

The API runs on `http://localhost:5050/api` by default. OTPs are printed in the backend console and are not sent by SMS.

Static media is served from `backend/public/media` at `http://localhost:5050/media/...`.

On startup, the server also creates missing tables and seeds dummy learning data for categories, courses, content, alphabets, quizzes, phonics, stories, and plans. It also creates dummy payment and subscription tables. It does not insert dummy users.

The admin console uses a separate `admin_users` table and `/api/admin` route namespace. On startup, the backend creates one admin account when no account exists for `ADMIN_EMAIL`.

Default local admin credentials:

```text
ADMIN_EMAIL=crisanttechnologies@gmail.com
ADMIN_PASSWORD=M@njula1105
```

Change these values in production before the first backend startup.

## Media Migration

Database media columns should use web paths such as:

```text
/media/images/courses/pet-animals.png
/media/audio/words/cat.wav
```

For production, either keep serving uploaded files from `/media` or replace these paths with full CDN URLs. The Flutter app accepts both relative `/media/...` paths and absolute `https://...` URLs.

## Dummy Payments

The payment flow is intentionally provider-neutral:

```text
POST /api/payments/create-order -> creates a dummy order
POST /api/payments/verify       -> marks the dummy order paid and activates subscription
GET  /api/subscriptions/me      -> returns active subscription
```

When integrating a real gateway, keep the controller/service contract and replace the dummy provider logic inside `src/application/payment/paymentService.js`.

## Endpoints

- `POST /api/auth/check-user`
- `POST /api/auth/register`
- `POST /api/auth/send-otp`
- `POST /api/auth/verify-otp`
- `POST /api/auth/logout`
- `GET /api/payments/plans`
- `POST /api/payments/create-order`
- `POST /api/payments/verify`
- `GET /api/subscriptions/me`
- `GET /api/user/profile`
- `GET /api/categories`
- `GET /api/subcategories`
- `GET /api/courses`
- `GET /api/content`
- `GET /api/alphabets`
- `GET /api/quizzes`
- `GET /api/phonics`
- `GET /api/stories`
- `GET /api/plans`
- `POST /api/admin/auth/login`
- `GET /api/admin/auth/me`
- `GET /api/admin/overview`
- `GET /api/admin/users`
- `GET /api/admin/users/:id`
- `PUT /api/admin/users/:id`
- `DELETE /api/admin/users/:id`
- `GET /api/admin/payments`
- `GET /api/admin/subscriptions`
- `GET /api/admin/notifications`
- `POST /api/admin/notifications`
- `GET /api/admin/resources/:resource`
- `POST /api/admin/resources/:resource`
- `PUT /api/admin/resources/:resource/:id`
- `DELETE /api/admin/resources/:resource/:id`
