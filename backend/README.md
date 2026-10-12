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

On startup, the server creates missing tables and applies the bundled original LangLex content migration once. It no longer seeds dummy learning content. The payment provider remains the existing test provider.

## Original learning catalog

The catalog comes from `https://kids.langlex.com/20260713_digitsta_langlex.sql`.
The downloaded raw dump is kept locally in `database/imports/` (gitignored because
it also contains legacy accounts and credentials). Only the 12 learning/catalog
tables used by this project are bundled in `database/data/original-content.json.gz`.
The manifest records the original dump checksum, artifact checksum, and table counts.

| Source table | Rows |
| --- | ---: |
| categories | 25 |
| subcategories | 379 |
| courses | 192 |
| Content | 8,371 |
| Alphabets | 2,371 |
| quizz | 3,771 |
| phonics_category | 2 |
| phonics_courses | 130 |
| Phonics | 1,226 |
| stories | 108 |
| site_language | 4 |
| subsc_plans | 2 |

Run from `backend/` to apply it explicitly (normal startup runs the same migration):

```bash
npm run import:original
```

The first application replaces the learning tables in a transaction. Before replacing
anything, it saves the previous catalog and affected plan/progress rows in
`content_migration_backups`. It retains current users, login identities, daily activity,
and payment/subscription records, remapping their plan references by free/paid access.
Old item progress is archived and reset because dummy IDs overlap original lesson IDs.
Legacy users, passwords, website settings, and historical transactions from the SQL
dump are not imported into the app's separate account system.

`content_migrations` prevents later startup/import runs from overwriting admin edits.
A failed import rolls back the catalog, references, progress, and migration marker.
Run this migration during a maintenance window when deploying to a running server.
Deployment to the hosted API is separate from importing the local database. The Flutter
app's default API is hosted; use `--dart-define=API_BASE_URL=http://<local-host>:5050/api/`
when testing against this local backend.

The API exposes 238 courses: 192 original course rows plus 46 course groups derived
from existing Assamese vocabulary, which has no source course table entries. It hides
empty/`Skip` vocabulary placeholders, leaving 7,538 usable vocabulary rows. All original
rows remain available in MySQL/admin. Numeric junk language values are excluded from
the language picker. Story passages are grouped by title/language/grade into 11 stories,
retaining all 108 passages and their individual audio. Quiz answer audio is supported.
The mobile app recognizes original Free/Login/Premium access labels and translated grades.

Original `/media/...` paths resolve to `https://kids.langlex.com/media/...`; the SQL
contains references, not media binaries. The app therefore needs access to that server.
Missing media represented by NULL/`NULL` becomes an empty path. The source plans' lorem
ipsum permission descriptions are omitted, while their prices and periods are retained.
Monthly plans now expire after a calendar month. Some source media is missing: sample
checks found 404 responses for Assamese camel audio and Maithili story audio; this import
cannot recover files absent from the original server.

To reproduce the bundled artifact from a newly downloaded copy of the same dump:

```bash
python3 scripts/extract-original-content.py database/imports/20260713_digitsta_langlex.sql
```

The extractor only parses allowlisted table values; it does not execute dump SQL.
A different snapshot requires a new migration version and review of its mappings.

Validation:

```bash
npm test
RUN_DB_TESTS=1 npm test
```

The integration test creates and removes an isolated test database to check rollback,
account preservation, and restart safety. It never resets the configured app database.

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


## Paginated catalog APIs

Large learning lists now default to `page=1&limit=20`. The maximum limit is 100;
invalid, zero, fractional, repeated, and excessive pagination values return HTTP 400.
Languages and subscription plans remain small unpaginated lookup lists.

Example: `GET /api/content?language=Hindi&course=पालतू%20जानवर&page=2&limit=20`

```json
{
  "content": [],
  "pagination": {
    "page": 2,
    "limit": 20,
    "total": 25,
    "total_pages": 2,
    "has_more": false
  }
}
```

The `content` array in a real response contains that page's rows. The same metadata
is returned for categories, subcategories, courses, alphabets, quizzes, phonics,
and stories. Filters are applied in SQL before counting/paging. Lists are ordered
by ID; `search` searches the relevant text fields, and `language` filters every list.
Words also accept course/category/subcategory/level; alphabets accept course/level;
quizzes accept topic/level; phonics accept course/category/subcategory/level;
stories and courses accept level. Translated Nursery/LKG/UKG labels are supported.
Course summaries include `word_count`, `category`, and `levels`; they do not embed
all vocabulary. Story pagination counts complete stories, keeping every passage
of each selected story together. Offset pages are stable for unchanged datasets;
concurrent admin insertions/deletions can shift page boundaries.

The Flutter app loads bounded language-specific home previews, pages library results
with server search, opens vocabulary pages on demand (including resuming a later
page), and offers paginated 20-item quiz/phonics practice sets with separate progress.
Alphabet browsing and the notification inbox also have page controls. Changing the
learning language refreshes previews. Page requests show loading, empty, and retry
states. A new Flutter build is required: older binaries only see the first page.

`GET /api/notifications?page=2&limit=20` includes global unread count and pagination.
Admin table pagination remains in place. Authenticated
`GET /api/admin/resource-options/:resource?page=1&limit=20&search=...`
serves searchable categories, subcategories, courses, or topics for form dropdowns,
including reference values beyond the former 100-row cutoff. List requests ignore
stale responses when filters change; dropdowns use server filtering and paging.

Startup adds indexes for language/ID, course/language/ID, and notification user/date/ID.
This deployment does not reimport the original catalog or reset user progress.

### Alphabet letter view

`GET /api/alphabets?language=English&view=letters&page=1&limit=20` pages
letter groups instead of example rows. Each item keeps the usual alphabet fields
and adds `example_count` and `examples` with the original word, image, and audio
rows. Counts in `pagination` refer to letter groups. English follows A–Z;
Devanagari and Kannada keep lesson groups in teaching order, followed by compound
letter lessons. All original examples are retained. Omitting `view=letters`
preserves the original row-based API used by older clients and administration.


### Account languages and temporary OTP delivery

After OTP verification, accounts without `selected_languages` choose exactly three of the supported catalog languages. `PUT /api/user/learning-setup` accepts `selected_languages` and `active_language` together with the existing learner fields. The chosen set cannot be replaced; subsequent saves may switch `active_language` within that set. Both legacy language fields are synchronized. First-time saves lock the account row to prevent competing requests from replacing the set.

Startup adds the nullable `selected_languages` JSON column without changing existing accounts. Existing users complete the same one-time selection. Authenticated catalog requests require this setup and use the account's active language; public catalog routes remain available for legacy clients.

`OTP_EXPOSE_CODE=true` temporarily includes the actual generated `display_otp` in registration, send/resend, and social mobile-verification responses, along with expiry and resend timing. The app displays it without storing it. This preview flow does not prove possession of a phone. Set the flag to `false` when SMS delivery is implemented; the preview then disappears. OTPs are redacted from client logs and are no longer printed by the server.

### Per-user learning completion

The Profile screen links to **Your progress**. It shows completed steps, a weighted
percentage, finished topics, and completion for Knowledge, Alphabets, Sounds,
Quizzes and Stories. The detailed screen filters by activity/status and lets the
learner inspect each of their selected languages. Progress uses the displayed
language, current academic level for Knowledge, and the user's actual entitlement.
Other activities follow the same language-only scope as their catalog screens.

`GET /api/user/learning-progress?language=English` requires the user's JWT. It
returns `completed_items`, `total_items`, `percent`, `completed_topics`,
`total_topics`, `locked_topics`, `saved_locked_items`, `has_premium`, `expires_at`,
and `topics` (each with counts, percentage, status, accessibility and quiz accuracy).
The language must belong to the user's saved selection. Counts come from current
catalog membership, never client totals. Shared item IDs count once per activity
in the overall total. Empty catalogs show 0/0 and 0%, not completion.

- Knowledge/Sounds earn a step when its card is explored; reaching the last card
  alone does not complete skipped cards.
- Alphabets earn only the example IDs explicitly marked as practiced. Filtered
  search results cannot complete unseen examples of the same letter.
- Quizzes earn completion for answers submitted, including wrong answers. The
  server compares the submitted `answer` with the stored answer; best-ever correct
  answers are displayed separately from completion and the current session score.
- Stories earn their passages when the learner taps Finished Reading.
- Restart clears the current practice session, preserving lifetime earned steps.
- Only an active, started, unexpired Premium subscription unlocks premium topics;
  choosing a plan in setup does not grant access. Upgrading expands the denominator.
  Expiry excludes locked items from the current percentage while retaining their
  earned steps. Renewal restores them. Added/removed catalog items recalculate the
  denominator/numerator without deleting historical completions.

`PUT /api/user/content-progress`, `POST /api/user/content-progress/item` and
`POST /api/user/content-progress/restart` accept an optional `event_id` for safe
retries and `session_id` to prevent older sessions overwriting a restarted session.
Restart also accepts `next_session_id`. New quiz submissions must include `answer`;
client `is_correct`, `total_items`, `score`, and completed status cannot fabricate
completion. Legacy quiz requests without event IDs/answers still record an answered
step, with unverified accuracy left unknown until an answer is submitted by the new app.

The Flutter client stores pending events and resume-session IDs per user on-device,
sends them with that user's token, and retries pending work on resume, refresh and
while online requests recover. Counts remain server-confirmed and pending/rejected
work is visibly labeled. Rejected premium/deleted-content events remain saved and
can be retried after access/content is restored; they do not block valid later work.
Offline durability lasts while app storage is retained; uninstalling/clearing app
storage before synchronization removes unsynced events.

Database startup runs the additive `src/infrastructure/database/learningProgress.js`
migration, creating `user_learning_completions`, `user_progress_events`, and
`learning_progress_migrations`. It backfills verified legacy item rows and completed
story passages once. It intentionally cannot recover practice that an earlier
restart already deleted, or infer skipped words from the old last-card status.
Existing accounts, catalog rows and practice sessions are preserved. Deploy the
backend migration before releasing the Flutter update. To apply only this migration
against an already initialized database, use its configured environment:

```sh
node -e "const {pool}=require('./src/infrastructure/database/db');require('./src/infrastructure/database/learningProgress')(pool).finally(()=>pool.end()).catch(e=>{console.error(e);process.exitCode=1})"
RUN_DB_TESTS=1 npm test
```

The integration suite creates and removes isolated test databases. It covers user
isolation, concurrent/idempotent writes, stale sessions, migration replay, alphabet
search, stories, upgrade/expiry/renewal, catalog edits, empty scopes and HTTP auth.

### Topic access and editing

Admin → Learning content → Topics → Edit topic changes shared titles, languages and access. Courses and stories use their existing access columns. Quiz access is stored once per `(language, topic)` in `quiz_topic_settings`; startup creates this table idempotently and existing quiz topics start Free. New questions inherit the topic setting. Free/Premium applies to all questions, including direct API requests and progress writes; changing access retains earned items and recalculates accessible progress totals. Run the updated backend before using these controls in the updated admin/mobile clients.

## Admin operations

Database initialization adds account-blocking columns, subscription source/notes, `admin_audit_log`, `admin_media`, and `admin_bulk_previews` without replacing existing data. Roles and permissions remain unchanged.

- Users: block/unblock with a reason. The API rejects blocked users on existing sessions and OTP/social login; the Flutter app clears the session when it receives `ACCOUNT_BLOCKED`. Unblocking does not change subscription dates.
- Subscriptions: grant a database Premium plan until a chosen expiry, adjust current expiry, or cancel access immediately. Grants replace active/scheduled subscriptions and create no payment order or revenue. Cancellation does not refund a payment.
- Audit history: successful admin content/topic changes, account edits/deletes, blocking, subscription operations, uploads, batches and notifications are recorded with administrator identity and before/after data. Credentials and push tokens are excluded. Database changes and audit writes commit together. Audit history starts with this migration; direct SQL changes are outside admin auditing.
- Media: `POST /api/admin/media` accepts authenticated raw binary uploads (`application/octet-stream`, URL-encoded `X-File-Name`). File signatures are checked. JPG/PNG/WebP/GIF images are capped at 5 MiB; MP3/WAV/OGG/Opus/M4A/AAC/FLAC audio at 20 MiB. Files are public under `/media/uploads/`, stored in `backend/public/media/uploads/`. Preserve and back up that directory alongside MySQL when deploying; do not place private documents there. Node 22+ is required by the media detector.
- Bulk tools: CSV is parsed in the admin UI and sent as JSON. Import or edit up to 100 records; topic edits apply shared fields to all members. Previews exercise validation inside a rolled-back transaction, expire after 15 minutes, and require explicit apply. Edits reject stale previews. Apply is atomic and idempotent for the same preview ID. Preview imports can consume auto-increment IDs; gaps are normal.

Verification: `RUN_DB_TESTS=1 npm test` runs integration tests in temporary databases and removes them afterward.

## Local curriculum workspace

The admin Learning content workspace follows the app's four sections: Knowledge,
Alphabets, Stories and Quizzes. Sounds is inside Knowledge. Subscription plans
are available from Settings. The old resource URLs redirect into this workflow.

`learning_topics` and `learning_topic_items` add stable topic membership and
standard assignments alongside the original catalog. They do not alter the
original SQL table definitions, item IDs or earned completions. Startup indexes
previously unmapped original rows; it does not replace saved assignments. Topic
standards are a JSON list of the six supported standards, or `["*"]` for All
standards. An empty imported list means Needs review. Item `standards=NULL`
inherits the topic; a non-null list preserves an individual assignment. Mixed
original groups retain their item assignments. Applying standards to every item
is an explicit admin action. Renaming topics updates legacy labels for the
existing app, while changing standards alone only updates the new metadata.

Authenticated catalog requests use the learner's saved standard and active
language. Catalog pages, opened content and progress membership use the same
standard policy, including explicit item overrides. Raw original grade fields
remain intact; learner-facing labels reflect the requested standard. Original
placeholder words stay in the database but are excluded from student preview,
matching the learner catalog. Premium access is evaluated independently.
Anonymous legacy requests without a standard retain their existing behavior.

Admin APIs are under `/api/admin/curriculum`: list/filter topics, create/edit a
topic, inspect its items, and create/edit/delete items inside that topic. Empty
topics can be deleted. Writes are transactional and audited; topic edits reject
stale revisions. The legacy raw-resource APIs remain available for compatibility;
use the curriculum APIs for new standard assignments. SQL imports of additional
source records require restarting the API to index those records. Replacing an
entire source dump still requires a separately reviewed migration.

Local verification: `RUN_DB_TESTS=1 npm test` includes an isolated curriculum
integration database. No production deployment is performed by this workflow.
