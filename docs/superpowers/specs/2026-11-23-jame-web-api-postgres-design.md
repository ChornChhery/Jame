# Jame Web API, PostgreSQL, and Secure Recovery Design

## Intent

Make Jame work in Chrome without exposing database credentials or opening a
database connection from the browser. Preserve the existing Flutter visual
design and move persistent operations behind a server-side API backed by
PostgreSQL.

## Why now

The current startup path expects MySQL at `localhost:3306` and requires a
non-empty `DB_PASSWORD`. The provided Docker status shows PostgreSQL, not
MySQL, running. More importantly, Flutter Web must not connect directly to a
database: database credentials would be shipped to clients, and the current
`mysql1` socket connection is not a suitable browser transport.

## Goals

- Keep the existing Flutter screens and visual design; change their data
  transport, and replace the insecure password-reset steps with verified email
  recovery.
- Add a containerized FastAPI REST service and a dedicated Jame PostgreSQL
  database. Do not reuse or alter the existing `pos-postgres` database unless
  explicitly approved later.
- Cover the app's persisted workflows: registration and sign-in, user/shop
  profile, product CRUD and code lookup, cart persistence, checkout and sale
  history, inventory movements, dashboard/report queries, and password
  recovery.
- Preserve the current Gmail-only sign-in and registration rule and enforce it
  on the server as well as in the Flutter form.
- Enforce account ownership on the server. Derive the acting user from
  authenticated credentials rather than trusting a client-supplied `user_id`.
- Keep database credentials server-side and out of Flutter assets, web builds,
  source control, and API responses.
- Use migrations for PostgreSQL schema changes and automated tests for
  authentication, data isolation, and transactional checkout.
- Configure the API origin for Flutter with a non-secret build/runtime setting.
  Configure CORS for explicit development and production origins.

## Proposed architecture

`Flutter app (Chrome/mobile/desktop) -> HTTPS/REST API (FastAPI) -> PostgreSQL`

The Flutter app uses an HTTP API client and typed request/response models. The
FastAPI service validates input, authenticates users, enforces ownership, and
performs database transactions. A health endpoint supports local startup and
deployment checks. API documentation is available through FastAPI's generated
OpenAPI interface.

Authentication uses server-verified password hashes (Argon2id). The browser
uses an HttpOnly, SameSite session cookie plus CSRF protection for
state-changing requests; native clients use a short-lived bearer credential
stored with platform-appropriate secure storage. Secrets and session
credentials are never placed in the Flutter web bundle or ordinary browser
local storage. Login and recovery requests are rate-limited. Password recovery
uses a one-time email code with expiration and attempt limits; responses
do not disclose whether an account exists. Local development uses Mailpit.
Production requires operator-provided SMTP settings and must not silently
report successful delivery when email cannot be sent.

## Data and behavior

The PostgreSQL schema preserves the current entities and relationships:
`users`, `products`, `sales`, `sale_items`, `cart_items`, and `inventories`,
with a `password_reset_challenges` table for short-lived recovery state. Use
PostgreSQL identity keys, foreign keys, unique constraints, indexes, and
numeric columns for money. A user owns their products, sales, cart, and
inventory records. Each account owns exactly one shop, matching the current
`users` row's shop fields and the existing user-based data relationships;
multi-shop membership and staff roles are not part of this migration.

The existing `inventories` entity is a stock-movement ledger, not the current
quantity balance: each record stores the stock before and after a
`SALE`, `STOCK_IN`, or `ADJUSTMENT`. The product quantity remains the current
balance.

Checkout is performed as a server transaction: validate the authenticated
user's cart and product ownership, reject checkout if any requested quantity
exceeds available stock, lock the relevant stock rows against concurrent
checkout, compute totals from stored product prices, record the sale and its
items, adjust stock, and record inventory movements. On failure, no partial
sale or stock update is committed. Store timestamps in UTC and use
Asia/Bangkok for the app's date-based report ranges and hourly/daily summaries,
consistent with the current app utilities. Reports continue to provide the
metrics currently requested by `DatabaseHelper`, including sales totals, low
stock, top sellers, payment method/category performance, inventory movement,
and reorder suggestions.

The backend starts with an empty dedicated Jame database. If a reachable
legacy MySQL database and credentials are later supplied, a separate reviewed
data migration can transfer its rows; no source data is assumed to be
available. The currently running `pos-postgres` is not treated as Jame data.

## Migration approach

1. Add the API service, isolated PostgreSQL service, schema migrations, health
   check, and automated backend tests.
2. Move sign-up/sign-in, session restoration, profile access, and product
   listing/CRUD to the API; verify the Chrome path end-to-end.
3. Move cart, checkout, sales/history, inventory, and report queries. Remove
   Flutter's direct MySQL connection and make API failures visible to the
   existing UI rather than reporting database errors as missing users or empty
   lists.
4. Replace the current public-information password reset check with
   email-verified one-time recovery; use Mailpit in development and require
   SMTP configuration for production.
5. Remove database dotenv loading and `.env` asset bundling from Flutter. Keep
   server secrets in an ignored server-side environment file; expose only the
   non-secret API base URL to Flutter.
6. Verify the full app, account-to-account isolation, and production HTTPS/CORS
   configuration.

## Success criteria

- Chrome can start and communicate with the API without MySQL socket errors or
  any database credential in the built assets.
- A user can register, sign in again, and retrieve only their own persistent
  data.
- Password recovery requires a valid, unexpired, single-use email challenge;
  invalid or unknown accounts do not reveal account existence.
- Product and cart changes persist; a completed checkout creates consistent
  sale, item, stock, and inventory records.
- Existing sales history, receipt, dashboard, and report flows use API-backed
  data and continue to work.
- Automated tests cover invalid authentication, cross-account access denial,
  and checkout rollback on failure.
- Flutter has no direct database-driver dependency or database connection
  settings.

## Non-goals

- Redesigning screens or changing the app's feature set beyond the secure
  password-recovery flow.
- Reusing another project's database or migrating its data.
- Offline synchronization or payment processor integration.
- Hosting the production service or provisioning production credentials.
- Provisioning production SMTP credentials; the service documents and requires
  them for production recovery email delivery.

## Implementation calls left to the builder

- Choose concrete API routes and JSON schemas that cover the existing call
  sites without leaking database-specific details into Flutter.
- Choose transaction/session implementation and test fixtures consistent with
  the authentication requirements above.
- Provide local Docker Compose configuration and safe example environment
  templates; never copy live credentials into the repository.

## Resolved design questions

- One shop per user is the call for this migration; it follows the current
  schema and leaves multi-shop support for a separate feature.
- `inventories` is a movement ledger; `products.quantity` is the current stock
  balance, matching the existing model and reporting queries.
- Checkout rejects insufficient stock and locks affected product rows so
  concurrent sales cannot oversell; this is the safest POS behavior.
- Timestamps are stored in UTC and reports use Asia/Bangkok, matching the
  existing UTC+7 conversion utilities.
- The existing username/shop/email password-reset check is replaced by a
  one-time email challenge; local delivery is tested with Mailpit, while
  production SMTP settings must be supplied by the operator.
