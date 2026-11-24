# Jame – AI Handoff (state as of 2026-11-24)

Paste this file into any AI assistant (or put it at the project root) so it can continue the work.
The user's local project folder is `D:\Jame` (Windows, PowerShell).

---

## 1. What the project is

**Jame** – all-in-one inventory & point-of-sale (POS) app for small shops.

| Layer | Tech |
|---|---|
| Client | Flutter (Dart SDK `^3.9.0`), `provider` state management, targets Web / Android / Windows / Linux |
| API | FastAPI (Python) in `backend/`, SQLAlchemy models, Alembic migrations, pytest tests |
| Database | PostgreSQL 16 (Docker, host port **5435**) |
| Dev mail | Mailpit (SMTP 1025, inbox http://localhost:8025) |

Flutter **never talks to the database directly**. It calls the API (`API_BASE_URL`, default `http://localhost:8000/api/v1`).
Auth: cookie + CSRF for web, bearer credentials for native. Reporting timezone: Asia/Bangkok (UTC+7).

### Main Flutter files
- `lib/main.dart` – app bootstrap, providers (`AuthProvider`, `AppProvider`, `SettingsProvider`)
- `lib/routes.dart` – named routes; protected routes wrapped by `_buildProtectedRoute`
- `lib/core/translations.dart` – **all UI text (English `en` + Khmer `km`)**
- `lib/core/utils.dart` – currency/date helpers (`formatCurrency`, `formatDateTime`, `formatDate`, `toShopTime` = UTC+7)
- `lib/providers/settings_provider.dart` – language/dark mode state (keeps `AppTranslations.currentLanguage` in sync)
- `lib/services/` – `jame_api.dart`, `jame_repository.dart`, `api_client.dart`
- `lib/screens/` – dashboard, products, scanner, cart, payment, receipt, reports, profile, payment history, notifications, auth, forgot password
- `lib/widgets/` – add/edit product dialog, manual sale dialog, product details dialog, language switch button
- `backend/app/` – `routers/`, `services/`, `schemas/`, `models.py`, `security.py`, `config.py`
- `docs/superpowers/` – original plan + spec for the Web/API/PostgreSQL migration (Tasks 1–8 all complete, see `.superpowers/sdd/.../progress.md`)

### Run it
```powershell
cd D:\Jame
docker compose up -d --wait postgres mailpit api
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```
Android emulator: `http://10.0.2.2:8000/api/v1`. Tests: `flutter test` and `cd backend; python -m pytest -q`.

---

## 2. What was done in this session: Thai → English + Khmer

**Goal:** remove every Thai-language string from the project and support only English (`en`) and Khmer (`km`).

### Done
1. **~715 hard-coded Thai strings in 17 Dart files** (screens, widgets, `routes.dart`) were replaced by translation lookups. 478 new keys (prefix `ui_…`) were added to **both** the `en` and `km` maps in `lib/core/translations.dart`.
2. **Two new helpers** in `AppTranslations`:
   - `AppTranslations.t('key', [arg0, arg1])` – context-free; placeholders are `{0}`, `{1}`…
   - `AppTranslations.label('English value')` – localized label for canonical values stored/compared in code (uses `val_<value>` keys)
   - `context.tr('key', [args])` now also accepts args.
3. **Canonical values changed from Thai to English** (they are stored/compared in code, display goes through `AppTranslations.label`):
   - Product categories: `Food & Beverage`, `Household Items`, `Stationery`, `Medicine & Medical Supplies`, `Clothing & Apparel`, `Electronics`, `Kitchenware`, `Other`
   - Report periods: `All`, `Today`, `Yesterday`, `This week`, `Last week`, `This month`, `Last month`, `This year`, `Last year`
   - Default product unit: `pcs` (was `ชิ้น`)
4. **Locale:** `th_TH` / `Locale('th','TH')` → `en_US` (this also removes Buddhist-era years in dates). Helpers renamed: `formatDateTimeThai→formatDateTime`, `formatDateThai→formatDate`, `toThaiTime→toShopTime`.
5. **Live language switching:** `lib/routes.dart` wrappers now also listen to `SettingsProvider`, so open pages rebuild when the language is toggled (context-free `AppTranslations.t` relies on this).
6. **Docs:** README Thai sample data/wording replaced and a "Localization" section added. `รายงานโปรเจค Application.docx` was converted to **`Project Report Application.docx`** (English paragraph followed by Khmer paragraph, all 30 screenshots kept).

### Verification status (important)
- The environment had **no Flutter SDK**. Every Dart file was checked with the Dart SDK parser (`dart format`), plus custom scripts: all translation keys exist in both `en` and `km`, placeholder counts match call arguments, no `AppTranslations` call is inside a `const` expression.
- **NOT yet done – please run on the real machine:** `flutter pub get`, `flutter analyze` (baseline before this work: 477 pre-existing warnings/info, 0 errors), `flutter test` (baseline: 16 passing), `cd backend; python -m pytest -q` (baseline: 30 passing), then click through the app in both languages.

### Intentionally NOT changed (decide with the user)
- **Update (round 2):** every `฿` in the UI was replaced by `AppConstants.currencySymbol` (default `$`, change it in `lib/core/constants.dart`, e.g. `'៛'`), and "Baht" labels now say USD. The profile currency dropdown still offers USD/KHR/THB (THB kept so existing users whose saved currency is `THB` don't break). Original note: **`฿`/THB and `PromptPay`** are payment/currency features, not language. The old `en` map used `$` for `currency_symbol`, so the app is currently inconsistent. If the shop is in Cambodia, consider USD (`$`) and/or KHR (`៛`) and replacing PromptPay with Bakong/KHQR.
- `AppUtils.isValidThaiID` (13-digit PromptPay ID validation) and a Thai-style PromptPay QR payload in `payment_screen.dart` are kept as-is.
- `.superpowers/sdd/.../review-5d02a2b..84505b7.diff` is a generated historical review diff that still contains the *old* Thai strings. It is not app code; delete or ignore it.
- `lib/screens/reports_screen_backup.dart` is an **unused** backup copy (not imported anywhere). Safe to delete.

### Known caveats / follow-ups
- **Existing data:** products already saved in PostgreSQL with Thai categories or unit `ชิ้น` keep those raw values (they will display as-is). Migrate with SQL if needed, e.g. `UPDATE products SET category='Other' WHERE category='อื่นๆ';` (do this per category).
- Khmer text was written by an AI; have a native speaker review `km` entries, especially report/analytics wording.
- Flutter Material widgets (date picker, etc.) have no Khmer delegate configured; add `flutter_localizations` + `supportedLocales: [Locale('en'), Locale('km')]` in `MaterialApp` if full Khmer system widgets are wanted. Khmer font rendering may need a bundled font on some platforms.
- Many auto-generated keys have bland names (e.g. `ui_text` = `'{0} {1}'`). Rename gradually.
- `Project Document.docx` (and the old report) contain a legacy MySQL `.env` example with DB host/user/password. The app no longer uses MySQL; treat those credentials as exposed and rotate them if they were ever real.
- Root `.env.example` still holds legacy MySQL placeholders (kept deliberately by the earlier migration).

---

## 3. How to add or change UI text

1. Add the key to **both** `'en'` and `'km'` in `lib/core/translations.dart`.
2. Use `context.tr('key')` inside `build` methods, or `AppTranslations.t('key', [value])` elsewhere. Never write a literal user-visible string in a widget.
3. If a widget was `const` and now contains a translation call, remove that `const`.
4. Values that are stored in the DB or compared in code must be English canonical strings; translate only the label.
5. Check: `grep` for Thai script should return nothing: `Select-String -Path .\lib\**\*.dart -Pattern '[\u0E01-\u0E5B]'` (the baht sign U+0E3F is allowed).

---

## 4. Suggested next tasks (in priority order)
1. Run `flutter pub get && flutter analyze && flutter test`; fix anything that surfaces from the i18n edit.
2. Manual UI pass in English and Khmer on: login/signup, dashboard, products (add/edit/delete/restock), scanner, cart → payment → receipt, reports (all tabs + period chips), payment history, profile.
3. Decide currency (THB vs USD/KHR) and payment method (PromptPay vs KHQR/Bakong); update `currency_symbol`, `AppUtils.formatCurrency`, receipts, PDF output.
4. Add Khmer Material localizations + Khmer font; review Khmer wording.
5. Delete `reports_screen_backup.dart` and the stale review diff; clean up the 477 analyzer warnings.
6. Add a widget test that toggles `SettingsProvider.setLanguage('km')` and asserts a translated string.
