# Jame Web API and PostgreSQL Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Jame's direct MySQL connections with a secure FastAPI/PostgreSQL API so Chrome and the other Flutter clients can use the existing POS workflows.

**Architecture:** Flutter calls a typed HTTP client; FastAPI owns authentication, authorization, validation, and transactions; PostgreSQL stores Jame data in a dedicated database. Browser sessions use HttpOnly cookies and CSRF protection, while native clients use short-lived bearer credentials in platform-secure storage. Local development runs PostgreSQL, the API, and Mailpit through Docker Compose.

**Tech Stack:** Existing Flutter/Dart app; Python 3.12+, FastAPI, SQLAlchemy 2, Alembic, PostgreSQL 16, pytest, Mailpit, Docker Compose.

**Spec:** [2026-11-23-jame-web-api-postgres-design.md](../specs/2026-11-23-jame-web-api-postgres-design.md)

## Global Constraints

- Keep the existing Flutter screens and visual design; replace the insecure password-reset steps with verified email recovery.
- Do not connect Flutter directly to PostgreSQL or MySQL; keep database credentials server-side and out of Flutter assets, web builds, source control, and API responses.
- Use a dedicated Jame PostgreSQL database; do not reuse or alter `pos-postgres`.
- Derive the acting account from authenticated credentials, never a client-supplied `user_id`.
- Preserve one shop per user and the `users`, `products`, `sales`, `sale_items`, `cart_items`, and `inventories` relationships; add short-lived password-reset challenges.
- Preserve the current Gmail-only registration/sign-in rule and enforce it on the server.
- Treat `inventories` as a movement ledger and `products.quantity` as current stock.
- Checkout must reject insufficient stock, lock stock rows, use stored product prices, and atomically write sale, items, stock changes, and inventory movements.
- Store timestamps in UTC and use Asia/Bangkok for date-based reports.
- Hash passwords with Argon2id. Browser sessions use HttpOnly, SameSite cookies and CSRF protection; native credentials use platform-appropriate secure storage.
- Rate-limit login and recovery; recovery codes are one-time, expiring, attempt-limited, and must not reveal whether an account exists.
- Use Mailpit locally and require operator-provided SMTP settings for production recovery email.
- Configure CORS for explicit origins and configure Flutter's API origin without embedding secrets.
- Surface API failures to the existing UI; do not turn failures into successful empty results or missing users.
- Do not add offline synchronization, payment processing, or production hosting as part of this migration.
- Preserve unrelated pre-existing worktree changes; inspect status and stage only task-owned hunks, using patch staging for files that already contain user edits.

## Review Focus

- A forged `user_id` or another account's resource ID must not permit cross-account reads or writes. Test in Task 3 with `test_products_are_scoped_to_authenticated_user`.
- A cookie-authenticated browser mutation without a valid CSRF token must be rejected. Test in Task 2 with `test_cookie_mutation_requires_csrf_token`.
- Two simultaneous checkouts for the last units must not oversell or leave partial rows. Test in Task 4 with `test_concurrent_checkout_never_oversells`.
- Sales on either side of Asia/Bangkok midnight must land in the expected report day. Test in Task 5 with `test_daily_report_uses_bangkok_day_boundary`.
- Unknown email, expired/replayed reset codes, SMTP failures, and API outages must not disclose account existence or appear successful. Test in Task 2 with `test_password_reset_is_generic_expiring_and_single_use`, and in Task 6 with `test_api_failure_is_reported_to_auth_provider`.

---

### Task 1: Bootstrap API and isolated development services

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/app/__init__.py`
- Create: `backend/app/config.py`
- Create: `backend/app/main.py`
- Create: `backend/tests/test_health.py`
- Create: `backend/tests/conftest.py`
- Create: `backend/Dockerfile`
- Create: `backend/.env.example`
- Create: `backend/README.md`
- Create: `compose.yaml`
- Modify: `README.md`

**Interfaces:**
- Produces: `create_app(settings: Settings | None = None) -> FastAPI`; `GET /health -> {"status": "ok"}` and `GET /ready` for PostgreSQL readiness; typed settings for API origin, database URL, and SMTP configuration.
- Uses Python 3.12+, FastAPI, pytest, and PostgreSQL 16. The Compose database must use an isolated Jame database and a host port that does not collide with the running `pos-postgres` mapping.

- [ ] **Step 1: Write the failing health and configuration tests**

Add `test_health_returns_ok_without_database`, `test_ready_requires_database`, `test_settings_require_server_database_configuration`, and `test_cors_allows_only_configured_origins`. Assert liveness returns exactly `{"status": "ok"}`, readiness fails when PostgreSQL is unavailable, and credentialed CORS accepts only configured origins.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend; python -m pytest tests/test_health.py -q`
Expected: FAIL because the API/settings modules do not exist.

- [ ] **Step 3: Implement the API skeleton and development services**

Create the FastAPI application factory, validated settings, liveness `/health` route, database readiness `/ready` route, explicit credentialed CORS allow-list, test fixtures, and Dockerfile. Add Compose services for PostgreSQL, API, and Mailpit; keep PostgreSQL private to the Compose network and configure health checks. Bind PostgreSQL to an available host port, the API to `8000`, and Mailpit's UI/SMTP to `8025`/`1025`; check for existing containers before choosing the database port. Add only placeholder secrets to `backend/.env.example`.

- [ ] **Step 4: Run API and service checks**

Run: `cd backend; python -m pytest tests/test_health.py -q`
Expected: PASS.

Run: `docker compose up -d --wait postgres mailpit api`
Expected: PostgreSQL and API health checks pass, Mailpit is running, and the API returns HTTP 200 from `/health`.

- [ ] **Step 5: Document local startup and commit**

Document the Compose command, API address, Mailpit UI, and Flutter API-base-URL configuration in `README.md`. Do not modify the existing root `.env` or the already-present untracked root `.env.example` without reviewing its contents and preserving unrelated user changes.

```bash
git add backend compose.yaml README.md
git commit -m "feat: bootstrap Jame API services" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 2: Add PostgreSQL schema, sessions, authentication, and recovery

**Files:**
- Create: `backend/app/db.py`
- Create: `backend/app/models.py`
- Create: `backend/app/schemas/auth.py`
- Create: `backend/app/schemas/users.py`
- Create: `backend/app/security.py`
- Create: `backend/app/dependencies.py`
- Create: `backend/app/routers/auth.py`
- Create: `backend/app/routers/profile.py`
- Create: `backend/app/services/email.py`
- Create: `backend/migrations/env.py`
- Create: `backend/migrations/versions/0001_initial_schema.py`
- Create: `backend/tests/test_auth.py`
- Create: `backend/tests/test_profile.py`
- Modify: `backend/app/main.py`
- Modify: `backend/pyproject.toml`
- Modify: `compose.yaml`

**Interfaces:**
- Produces: `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`, `GET /api/v1/auth/session`, `POST /api/v1/auth/logout`, `POST /api/v1/auth/password-reset/request`, `POST /api/v1/auth/password-reset/confirm`, `GET /api/v1/profile`, and `PATCH /api/v1/profile`.
- Authenticated user responses contain profile fields only, never password hashes. Browser responses set HttpOnly/SameSite cookies and issue CSRF tokens; native login returns a short-lived bearer credential with a refresh flow.
- Produces PostgreSQL models for `users`, `sessions`, `products`, `sales`, `sale_items`, `cart_items`, `inventories`, `password_reset_challenges`, and database-backed `auth_rate_limits`; database session and user dependencies are injected into routes.

- [ ] **Step 1: Write failing auth, cookie/CSRF, and recovery tests**

Add tests named `test_register_hashes_password_and_never_returns_hash`, `test_register_rejects_non_gmail_email`, `test_cookie_mutation_requires_csrf_token`, `test_password_reset_is_generic_expiring_and_single_use`, `test_smtp_failure_is_not_reported_as_delivered`, and `test_profile_requires_authenticated_session`. Assert registration creates a session, Argon2id verification, server-side Gmail-only validation, generic responses for known/unknown emails, one-time code rejection on expiry/replay, SMTP errors are surfaced without claiming delivery, and no password hash in any response.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend; python -m pytest tests/test_auth.py tests/test_profile.py -q`
Expected: FAIL because models and routes are not implemented.

- [ ] **Step 3: Implement migrations, auth, profile, and email delivery**

Add SQLAlchemy models and Alembic migration. Store only a hash of each reset code with expiry, attempt count, and used timestamp. Hash passwords with Argon2id. Use a short-lived server-side session for browser cookies and CSRF validation for cookie-authenticated mutations. Use a one-time email code, generic reset-request response, and Mailpit SMTP in development. Enforce login and recovery windows through database-backed counters keyed by a hash of normalized email and client address. Update profiles only for the authenticated user.

- [ ] **Step 4: Run the tests and migrations**

Run: `docker compose up -d --wait postgres mailpit`

Run: `cd backend; python -m pytest tests/test_auth.py tests/test_profile.py -q`
Expected: PASS against the isolated PostgreSQL test database; profile and auth responses contain no hash or reset secret.

- [ ] **Step 5: Commit**

```bash
git add backend compose.yaml
git commit -m "feat: add API authentication and recovery" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 3: Add product catalog and stock-adjustment API

**Files:**
- Create: `backend/app/schemas/products.py`
- Create: `backend/app/schemas/inventory.py`
- Create: `backend/app/routers/products.py`
- Create: `backend/app/routers/inventory.py`
- Create: `backend/tests/test_products.py`
- Create: `backend/tests/test_inventory.py`
- Modify: `backend/app/main.py`

**Interfaces:**
- Produces `GET/POST /api/v1/products`, `GET/PATCH/DELETE /api/v1/products/{product_id}`, `GET /api/v1/products/by-code/{code}`, `GET /api/v1/inventory/low-stock`, and `POST /api/v1/inventory/adjustments`.
- Product JSON preserves `id`, `name`, `price`, `quantity`, `low_stock`, `code`, `category`, `unit`, `image`, `created_at`, and `updated_at`; `user_id` is derived from the session and is not accepted as authority from request JSON.
- Stock edits record `stock_before`, `stock_after`, `change_type`, optional `reference_id`, and `notes` in `inventories`.

- [ ] **Step 1: Write failing catalog, ownership, and inventory tests**

Add `test_products_are_scoped_to_authenticated_user`, `test_duplicate_product_code_is_rejected_per_user`, and `test_stock_adjustment_records_before_and_after`. Include a request containing a forged `user_id` and prove it cannot read or alter another user's product.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend; python -m pytest tests/test_products.py tests/test_inventory.py -q`
Expected: FAIL because product and inventory routes do not exist.

- [ ] **Step 3: Implement catalog and inventory routes**

Validate price and quantity, enforce per-user code uniqueness, derive ownership from `current_user`, and use ownership-scoped queries for all product reads/writes. Write inventory ledger entries transactionally when an edit changes stock.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend; python -m pytest tests/test_products.py tests/test_inventory.py -q`
Expected: PASS, including cross-account denial.

- [ ] **Step 5: Commit**

```bash
git add backend/app backend/tests
git commit -m "feat: add product and inventory API" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 4: Add cart, atomic checkout, and sale history API

**Files:**
- Create: `backend/app/schemas/cart.py`
- Create: `backend/app/schemas/sales.py`
- Create: `backend/app/routers/cart.py`
- Create: `backend/app/routers/sales.py`
- Create: `backend/app/services/checkout.py`
- Create: `backend/tests/test_cart.py`
- Create: `backend/tests/test_checkout.py`
- Modify: `backend/app/main.py`

**Interfaces:**
- Produces `GET /api/v1/cart`, `PUT /api/v1/cart/items/{product_id}`, `DELETE /api/v1/cart/items/{product_id}`, `DELETE /api/v1/cart`, `POST /api/v1/sales/checkout`, `GET /api/v1/sales`, and `GET /api/v1/sales/{sale_id}/items`.
- Checkout accepts payment method and optional customer/description fields; the server reads the authenticated user's persisted cart, computes amounts from database prices, and returns the created sale and receipt number.
- Sale history and cart queries are always scoped to the authenticated user.

- [ ] **Step 1: Write failing cart and checkout transaction tests**

Add `test_cart_rejects_products_owned_by_another_user`, `test_checkout_rejects_insufficient_stock_without_partial_records`, and `test_concurrent_checkout_never_oversells`. Assert cart clearing and inventory ledger writes occur only after a successful transaction.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend; python -m pytest tests/test_cart.py tests/test_checkout.py -q`
Expected: FAIL because routes and checkout service do not exist.

- [ ] **Step 3: Implement cart and transactional checkout**

Use PostgreSQL transactions and row-level locks for affected products. Reject insufficient stock with a stable conflict response. Atomically insert sale and sale items, update stock, write `SALE` inventory movements, and clear the cart. Roll back every write on any failure.

- [ ] **Step 4: Run tests, including concurrency tests**

Run: `cd backend; python -m pytest tests/test_cart.py tests/test_checkout.py -q`
Expected: PASS; concurrent checkout never produces negative stock or partial sales.

- [ ] **Step 5: Commit**

```bash
git add backend/app backend/tests
git commit -m "feat: add transactional checkout API" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 5: Add reports and analytics API

**Files:**
- Create: `backend/app/schemas/reports.py`
- Create: `backend/app/routers/reports.py`
- Create: `backend/app/services/reports.py`
- Create: `backend/tests/test_reports.py`
- Modify: `backend/app/main.py`

**Interfaces:**
- Produces `GET /api/v1/reports/dashboard` for today's totals/sales, top products, and low stock, plus authenticated `GET /api/v1/reports/sales?start=&end=`, `/reports/sales/hourly`, `/reports/sales/daily`, `/reports/products/top`, `/reports/customers/purchase-history`, `/reports/inventory/movement`, `/reports/inventory/reorder-suggestions`, `/reports/products/performance`, `/reports/customers/segmentation`, `/reports/revenue-projection`, `/reports/payment-methods`, `/reports/categories`, and `/reports/domestic-export-sales`.
- Date parameters are ISO-8601 instants; aggregation day/hour boundaries use Asia/Bangkok while stored timestamps remain UTC. Preserve the response keys consumed by the existing `AppProvider` and report screens.
- Limit parameters are bounded; all report queries derive account ownership from authentication.

- [ ] **Step 1: Write failing report contract and timezone tests**

Add `test_daily_report_uses_bangkok_day_boundary`, `test_report_cannot_read_other_users_sales`, `test_dashboard_report_returns_today_totals_top_products_and_low_stock`, and `test_report_series_preserves_consumer_response_keys`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend; python -m pytest tests/test_reports.py -q`
Expected: FAIL because report routes and services do not exist.

- [ ] **Step 3: Implement report queries**

Translate the current `DatabaseHelper` report queries to PostgreSQL SQLAlchemy expressions. Use explicit timezone conversion and stable sort/limit behavior; aggregate only records owned by the authenticated user.

- [ ] **Step 4: Run report tests**

Run: `cd backend; python -m pytest tests/test_reports.py -q`
Expected: PASS, including the Bangkok midnight boundary and cross-account denial.

- [ ] **Step 5: Commit**

```bash
git add backend/app backend/tests
git commit -m "feat: add sales and inventory reports API" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 6: Add Flutter API transport and migrate authentication

**Files:**
- Create: `lib/core/api_config.dart`
- Create: `lib/services/api_client.dart`
- Create: `lib/services/jame_api.dart`
- Create: `test/services/api_client_test.dart`
- Create: `test/services/jame_api_test.dart`
- Create: `test/providers/auth_provider_test.dart`
- Create: `test/screens/forgot_password_screen_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/providers/auth_provider.dart`
- Modify: `lib/models/user.dart`
- Modify: `lib/screens/auth_screens.dart`
- Modify: `lib/screens/forgot_password_screen.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

**Interfaces:**
- Produces `Future<Map<String, dynamic>> ApiClient.getJson(String path, {Map<String, String> queryParameters = const {}})`, `Future<Map<String, dynamic>> postJson(String path, {Object? body})`, `Future<Map<String, dynamic>> patchJson(String path, {Object? body})`, `Future<void> delete(String path)`, and `ApiException(statusCode, code, message)`. `JameApi` provides typed `login`, `register`, `restoreSession`, `logout`, `updateProfile`, `requestPasswordReset`, `confirmPasswordReset`, and `checkReadiness` methods.
- Read the non-secret API URL from `--dart-define=API_BASE_URL`; default local Web URL is `http://localhost:8000/api/v1`. Browser requests include credentials and CSRF headers; native requests attach a short-lived token from secure storage.
- `User` represents public profile data and does not contain or serialize a password.

- [ ] **Step 1: Write failing API-client and auth-provider tests**

Add `test_api_client_uses_configured_base_url`, `test_api_client_preserves_server_error`, `test_auth_provider_restores_session_from_api`, `test_api_failure_is_reported_to_auth_provider`, `test_auth_connectivity_check_uses_api_readiness`, and `test_password_reset_screen_uses_email_code`. Assert no database host/password is read by Flutter code and auth does not persist a user ID as proof of session.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/services/api_client_test.dart test/services/jame_api_test.dart test/providers/auth_provider_test.dart test/screens/forgot_password_screen_test.dart`
Expected: FAIL because the API client and API-backed auth provider do not exist.

- [ ] **Step 3: Implement the Flutter API client and auth flows**

Use the existing `http` dependency with an injectable client for tests. Configure the web client for cookie credentials and CSRF, use secure storage for native bearer credentials, map server errors to `ApiException`, implement the API readiness check used by the login/signup screens, and implement email-code reset in `ForgotPasswordScreen`. Never hash or persist the new password in Flutter.

- [ ] **Step 4: Run tests and Flutter analysis**

Run: `flutter test test/services/api_client_test.dart test/services/jame_api_test.dart test/providers/auth_provider_test.dart test/screens/forgot_password_screen_test.dart`
Expected: PASS.

Run: `flutter analyze lib/core/api_config.dart lib/services lib/providers/auth_provider.dart lib/models/user.dart lib/screens/auth_screens.dart lib/screens/forgot_password_screen.dart`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/core/api_config.dart lib/services/api_client.dart lib/services/jame_api.dart test/services/api_client_test.dart test/services/jame_api_test.dart test/providers/auth_provider_test.dart test/screens/forgot_password_screen_test.dart
git add -p lib/main.dart lib/providers/auth_provider.dart lib/models/user.dart lib/screens/auth_screens.dart lib/screens/forgot_password_screen.dart pubspec.yaml pubspec.lock
git commit -m "feat: add Flutter API authentication" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 7: Migrate POS data providers and screens to the API

**Files:**
- Create: `lib/services/jame_repository.dart`
- Create: `test/services/jame_repository_test.dart`
- Create: `test/providers/app_provider_test.dart`
- Modify: `lib/providers/app_provider.dart`
- Modify: `lib/screens/dashboard_screen.dart`
- Modify: `lib/screens/reports_screen.dart`

**Interfaces:**
- Produces `JameRepository({required JameApi api})` operations `Future<List<Product>> getProducts()`, `Future<Product?> getProductByCode(String code)`, `Future<Product> createProduct(Product product)`, `Future<void> updateProduct(Product product)`, `Future<void> deleteProduct(int productId)`, `Future<void> adjustStock(int productId, int newQuantity, {required String changeType, String? notes})`, `Future<List<CartItem>> getCart()`, `Future<void> setCartQuantity(int productId, int quantity)`, `Future<void> clearCart()`, `Future<Sale> checkout({required String paymentMethod})`, `Future<List<Sale>> getSales({DateTime? start, DateTime? end})`, and `Future<List<SaleItem>> getSaleItems(int saleId)`. Add typed report response models for each endpoint in Task 5. User IDs are not accepted as authorization parameters.
- Provider methods keep UI-facing behavior where valid, but authenticated ownership is not sent as authority. Checkout invokes one server operation; the client does not separately decrement stock, write sale rows, write inventory movements, or clear the cart.
- API/network/authorization errors remain distinguishable from legitimate empty data and are exposed through existing provider error/loading state.

- [ ] **Step 1: Write failing provider/repository tests**

Add `test_checkout_is_one_api_operation`, `test_cart_api_failure_is_not_reported_as_empty_cart`, and `test_report_error_is_exposed_to_provider`. Assert successful checkout updates local state only from the server response and failure does not clear the local/persisted cart.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/services/jame_repository_test.dart test/providers/app_provider_test.dart`
Expected: FAIL because the repository migration and provider tests do not exist.

- [ ] **Step 3: Implement API-backed repository and providers**

Map the current `DatabaseHelper` and `AppProvider` operations to Task 3-5 endpoints. Replace dashboard direct database calls with provider/repository calls. Leave cart, payment, sales-history, and receipt layouts intact while routing them through the migrated provider interface. Do not mask transport failures as `null`, empty lists, or success-shaped defaults.

- [ ] **Step 4: Run focused Flutter tests and analysis**

Run: `flutter test test/services/jame_repository_test.dart test/providers/app_provider_test.dart test/widget_test.dart`
Expected: PASS.

Run: `flutter analyze lib/providers lib/screens lib/services`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/jame_repository.dart test/services/jame_repository_test.dart test/providers/app_provider_test.dart lib/providers/app_provider.dart
git add -p lib/screens/dashboard_screen.dart lib/screens/reports_screen.dart
git commit -m "refactor: route POS data through API" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 8: Remove direct database access and verify end-to-end behavior

**Files:**
- Delete: `lib/core/connectdb.dart`
- Delete: `lib/database/database_helper.dart`
- Modify: `lib/main.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `README.md`
- Modify: `backend/README.md`
- Modify: existing Flutter tests and `backend/tests/` as needed
- Create: `backend/tests/test_e2e_pos_flow.py`

**Interfaces:**
- Flutter startup no longer loads `.env`, initializes MySQL, or imports `mysql1`; Flutter assets contain no database configuration.
- Local startup instructions use Docker Compose for PostgreSQL, FastAPI, and Mailpit, plus the Flutter API-base-URL define.
- Backend production instructions require HTTPS, explicit CORS origins, database secrets, and SMTP configuration.

- [ ] **Step 1: Write failing startup and end-to-end contract checks**

Create `test/startup_configuration_test.dart` to assert Flutter source/assets contain no `ConnectDB`, `mysql1`, `DB_PASSWORD`, or dotenv database loading. Add an end-to-end API test that registers a user, logs in, creates a product, checks out a sale, and verifies the resulting stock/history.

- [ ] **Step 2: Run checks to verify the remaining direct database access is detected**

Run: `flutter test test/startup_configuration_test.dart`
Expected: FAIL until direct MySQL configuration and startup initialization are removed.

- [ ] **Step 3: Remove the legacy database path and finish documentation**

Delete the direct MySQL connector and helper after all call sites are migrated. Remove `mysql1` and `flutter_dotenv` from the Flutter manifest and lockfile, remove `.env` from Flutter assets, and remove MySQL startup from `main.dart`. Preserve the existing ignored root `.env`; do not copy any values into backend files. Document API, SMTP, CORS, and local-device URL setup.

- [ ] **Step 4: Run complete verification**

Run: `cd backend; python -m pytest -q`
Expected: all backend unit and integration tests PASS against the isolated Compose database.

Run: `flutter test`
Expected: all Flutter tests PASS.

Run: `flutter analyze`
Expected: no errors.

Run: `flutter build web --dart-define=API_BASE_URL=http://localhost:8000/api/v1`
Expected: Web build succeeds; inspect build assets to confirm no database credentials or MySQL driver code is present.

Run: `docker compose up -d --wait postgres mailpit api`
Expected: services become ready; manual Chrome smoke test can register, log in, create a product, perform checkout, and reload the resulting sale/report data.

- [ ] **Step 5: Commit**

```bash
git add -u -- lib/core/connectdb.dart lib/database/database_helper.dart
git add backend/tests/test_e2e_pos_flow.py test/startup_configuration_test.dart
git add -p lib/main.dart README.md backend/README.md pubspec.yaml pubspec.lock
git commit -m "feat: complete PostgreSQL API migration" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
