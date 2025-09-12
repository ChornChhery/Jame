# 🛍️ Jame - All-in-One Inventory & Sales Management App
## Complete Project Documentation with User Management

---

## 📋 Table of Contents
1. [App Concept Overview](#app-concept-overview)
2. [Goals & Core Features](#goals--core-features)
3. [App Pages & User Flow](#app-pages--user-flow)
4. [Tech Stack](#tech-stack)
5. [Database Design with User Management](#database-design-with-user-management)
6. [Database Relationships](#database-relationships)
7. [Project Structure](#project-structure)
8. [Color Palette & Design System](#color-palette--design-system)
9. [Architecture & Implementation](#architecture--implementation)
10. [Authentication & User Management](#authentication--user-management)
11. [Getting Started Checklist](#getting-started-checklist)
12. [Future Upgrades](#future-upgrades)

---

## 🎯 App Concept Overview

**Jame** is a **smart, offline-capable mobile app with user authentication** to help manage your **shop's inventory, sales, and payments** - all from your smartphone using **QR code scanning** and **receipt generation**. Each user can manage their own shop data and view their personal analytics.

The app will help you:
- Secure login/signup for individual users
- Track products and stock per user
- Scan products at checkout
- Calculate total prices
- Accept payments via customer-scanned QR code
- Automatically generate receipts
- View personal sales analytics and reports

---

## 🎯 Goals & Core Features

### Goal of the App
To make your shop:
- **Secure** with user authentication
- **Faster** in checkout
- **Smarter** in managing stock
- **More professional** with QR-based payments and digital receipts
- **Analytics-driven** with personal sales insights

All while being fully **offline-capable**, cost-efficient, and simple to use.

### 🔐 User Management & Authentication
- User registration and secure login
- Password protection with encryption
- Profile management (name, shop details, contact info)
- Data isolation per user (each user sees only their data)
- Personal analytics dashboard

### 🔍 Product & Inventory Management (Per User)
- Add/edit/delete product information
- Store product name, price, quantity, and QR/product code
- Scan product QR code to retrieve info instantly
- Track stock-in and stock-out
- Automatic stock reduction after sale
- Low stock alerts

### 🛒 POS & Cart System
- Scan multiple products to add to a virtual cart
- Auto-display product details (name, price, quantity)
- Modify quantity if needed
- Display real-time total price
- Option to remove or edit items from cart

### 💳 Payment via QR Code
- After finalizing the cart, app generates a **payment QR code**
- Customer scans the QR using their preferred payment app
- App confirms payment (manually or via API)
- Once paid, transaction is marked complete

### 🧾 Receipt & Sales Tracking
- Generate a receipt with shop and user details
- Store all sales data linked to the logged-in user
- Export or print receipts
- Share receipt via WhatsApp, email, etc.

### 📊 Personal Analytics & Reports
- View daily/weekly/monthly sales for logged-in user
- Track best-selling products
- Visual overview of stock levels
- Personal sales history with filtering
- Revenue tracking and profit analysis

---

## 📋 App Pages & User Flow

| **Screen** | **Function** |
|------------|-------------|
| **Login/Signup** | User authentication (required) |
| **Profile Setup** | Initial shop details and settings |
| **Dashboard** | Personal overview of sales, inventory, alerts |
| **Scan Product** | Use camera to scan QR or enter product code |
| **Cart / Checkout** | View items scanned, update quantity, view total price |
| **Payment Screen** | Show total and display dynamic payment QR code |
| **Receipt Page** | View/save/share printable receipt |
| **Products List** | Add/edit/remove user's products and stock |
| **Personal Reports** | Track user's past sales and inventory performance |
| **Profile Settings** | Manage user profile and shop settings |

### 🔄 Example User Flow: Complete Process
1. **Login** to the app with credentials
2. Open the scanner and scan QR code on each product
3. Each scanned product is added to the cart
4. Total price is auto-calculated
5. Tap **Checkout**
6. App generates **payment QR code** with user's payment details
7. Customer scans the QR and pays
8. App confirms payment
9. User's inventory is updated
10. Receipt is generated with user's shop details → print or share
11. Sale is recorded in user's analytics

---

## 🧱 Tech Stack

| **Layer** | **Technology** | **Purpose** |
|-----------|----------------|-------------|
| **UI** | Flutter | Build responsive, cross-platform mobile app |
| **Language** | Dart | Used with Flutter to build logic and UI |
| **Database** | SQLite (sqflite) | Local database for storing users, products, sales, etc. |
| **Authentication** | Local (SQLite) + crypto | Secure password hashing and user session |
| **QR Scanner** | mobile_scanner | Scan product QR codes |
| **QR Generator** | qr_flutter | Generate payment QR codes |
| **PDF Generator** | pdf + printing | Create and print/share receipts |
| **Security** | crypto (Dart package) | Password hashing and encryption |

---

## 🗄️ Database Design with User Management

### Database Schema with User Table (ONLY NEW TABLE)

#### 1. **users** table (NEW - Only Additional Table)
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL, -- Encrypted password
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    shop_name TEXT NOT NULL,
    shop_address TEXT,
    shop_phone TEXT,
    shop_email TEXT,
    currency TEXT DEFAULT 'THB', -- Default Thai Baht
    payment_qr TEXT, -- Store QR payment details (PromptPay, etc.)
    profile_image TEXT, -- Local image path
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. **products** table (UPDATED - Added user_id only)
```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL, -- Links product to specific user
    name TEXT NOT NULL,
    price REAL NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    low_stock INTEGER DEFAULT 5,
    code TEXT NOT NULL, -- QR/Barcode for scanning (unique per user)
    category TEXT,
    unit TEXT DEFAULT 'pcs',
    image TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    UNIQUE(user_id, code) -- Code unique per user
);
```

#### 3. **sales** table (UPDATED - Added user_id only)
```sql
CREATE TABLE sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL, -- Links sale to specific user
    sale_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount REAL NOT NULL,
    payment_status TEXT DEFAULT 'Completed',
    receipt_number TEXT NOT NULL, -- Format: USERNAME-YYYYMMDD-001
    payment_method TEXT DEFAULT 'QR',
    description TEXT,
    customer_name TEXT,
    customer_phone TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    UNIQUE(user_id, receipt_number) -- Receipt number unique per user
);
```

#### 4. **sale_items** table (No changes - inherits user through sale)
```sql
CREATE TABLE sale_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sale_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    total_price REAL NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products (id)
);
```

#### 5. **inventories** table (UPDATED - Added user_id only)
```sql
CREATE TABLE inventories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL, -- Links inventory change to specific user
    product_id INTEGER NOT NULL,
    change_type TEXT NOT NULL, -- 'SALE', 'STOCK_IN', 'ADJUSTMENT'
    quantity_change INTEGER NOT NULL,
    previous_quantity INTEGER NOT NULL,
    new_quantity INTEGER NOT NULL,
    reference_id INTEGER, -- sale_id if change is from a sale
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products (id)
);
```

### Database Indexes (for performance)
```sql
-- User-related indexes (NEW)
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- Updated existing indexes to include user_id
CREATE INDEX idx_products_user_id ON products(user_id);
CREATE INDEX idx_products_code_user ON products(user_id, code);
CREATE INDEX idx_products_category_user ON products(user_id, category);

CREATE INDEX idx_sales_user_id ON sales(user_id);
CREATE INDEX idx_sales_date_user ON sales(user_id, sale_date);
CREATE INDEX idx_sales_status_user ON sales(user_id, payment_status);

CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product_id ON sale_items(product_id);

CREATE INDEX idx_inventory_user_id ON inventories(user_id);
CREATE INDEX idx_inventory_product_user ON inventories(user_id, product_id);
CREATE INDEX idx_inventory_created_user ON inventories(user_id, created_at);
```

---

## 🔗 Database Relationships

### Complete Entity Relationship Diagram

```
users (1) ←→ (∞) products
users (1) ←→ (∞) sales  
users (1) ←→ (∞) inventories

products (1) ←→ (∞) sale_items
products (1) ←→ (∞) inventories

sales (1) ←→ (∞) sale_items
sales (1) ←→ (1) inventories (via reference_id)
```

### Detailed Relationships:

#### **users → products (One-to-Many)**
- One user can have many products
- Each product belongs to exactly one user
- When user is deleted, all their products are deleted (CASCADE)
- Product codes are unique per user (not globally unique)

#### **users → sales (One-to-Many)**
- One user can have many sales transactions
- Each sale belongs to exactly one user
- When user is deleted, all their sales are deleted (CASCADE)
- Receipt numbers are unique per user

#### **users → inventories (One-to-Many)**
- One user can have many inventory changes
- Each inventory log belongs to exactly one user
- When user is deleted, all their inventory logs are deleted (CASCADE)

#### **sales → sale_items (One-to-Many)**
- One sale can contain many items
- Each sale item belongs to exactly one sale
- When sale is deleted, all its items are deleted (CASCADE)

#### **products → sale_items (One-to-Many)**
- One product can appear in many sale items
- Each sale item references exactly one product
- Products cannot be deleted if they have sale history

#### **products → inventories (One-to-Many)**
- One product can have many inventory change logs
- Each inventory change affects exactly one product

#### **sales → inventories (One-to-One) [Optional]**
- Some inventory changes reference a specific sale
- This is optional (reference_id can be NULL for manual adjustments)

---

## 📁 Project Structure (Updated with User Management)

```
jame_inventory_app/
├── lib/
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   ├── app_sizes.dart
│   │   │   └── app_routes.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── date_formatter.dart
│   │   │   ├── currency_formatter.dart      # UPDATED - Default THB
│   │   │   ├── qr_helper.dart
│   │   │   ├── receipt_generator.dart
│   │   │   ├── validators.dart
│   │   │   ├── encryption_helper.dart       # NEW - Password hashing
│   │   │   └── session_manager.dart         # NEW - User session management
│   │   │
│   │   ├── services/
│   │   │   ├── database_service.dart
│   │   │   ├── auth_service.dart            # NEW - Authentication service
│   │   │   ├── user_service.dart            # NEW - User management
│   │   │   ├── pdf_service.dart
│   │   │   ├── payment_service.dart
│   │   │   ├── backup_service.dart
│   │   │   └── notification_service.dart
│   │   │
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       └── text_styles.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user.dart                    # NEW - User model
│   │   │   ├── product.dart                 # UPDATED - Added user_id
│   │   │   ├── category.dart
│   │   │   ├── sale.dart                    # UPDATED - Added user_id
│   │   │   ├── sale_item.dart
│   │   │   ├── inventory_log.dart           # UPDATED - Added user_id
│   │   │   ├── cart_item.dart
│   │   │   └── app_settings.dart
│   │   │
│   │   ├── database/
│   │   │   ├── database_helper.dart         # UPDATED - Added user table
│   │   │   ├── migrations.dart              # UPDATED - User table migration
│   │   │   └── dao/
│   │   │       ├── user_dao.dart            # NEW - User queries
│   │   │       ├── product_dao.dart         # UPDATED - Filter by user_id
│   │   │       ├── category_dao.dart
│   │   │       ├── sale_dao.dart            # UPDATED - Filter by user_id
│   │   │       ├── inventory_dao.dart       # UPDATED - Filter by user_id
│   │   │       └── settings_dao.dart
│   │   │
│   │   └── repositories/
│   │       ├── user_repository.dart         # NEW - User business logic
│   │       ├── auth_repository.dart         # NEW - Authentication logic
│   │       ├── product_repository.dart      # UPDATED - User-scoped operations
│   │       ├── sale_repository.dart         # UPDATED - User-scoped operations
│   │       ├── inventory_repository.dart    # UPDATED - User-scoped operations
│   │       └── settings_repository.dart
│   │
│   ├── presentation/
│   │   ├── pages/
│   │   │   ├── splash/
│   │   │   │   └── splash_screen.dart
│   │   │   │
│   │   │   ├── auth/                        # NEW - Authentication pages
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── signup_screen.dart
│   │   │   │   ├── forgot_password_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── auth_form.dart
│   │   │   │       ├── password_field.dart
│   │   │   │       └── social_login_buttons.dart
│   │   │   │
│   │   │   ├── profile/                     # NEW - User profile pages
│   │   │   │   ├── profile_screen.dart
│   │   │   │   ├── edit_profile_screen.dart
│   │   │   │   ├── shop_settings_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── profile_header.dart
│   │   │   │       ├── shop_info_card.dart
│   │   │   │       └── profile_menu_item.dart
│   │   │   │
│   │   │   ├── dashboard/
│   │   │   │   ├── dashboard_screen.dart    # UPDATED - User-specific data
│   │   │   │   └── widgets/
│   │   │   │       ├── user_welcome_header.dart     # NEW
│   │   │   │       ├── personal_sales_summary.dart  # UPDATED
│   │   │   │       ├── quick_actions_grid.dart
│   │   │   │       └── low_stock_alerts.dart
│   │   │   │
│   │   │   ├── products/
│   │   │   │   ├── product_list_screen.dart         # UPDATED - User's products only
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   ├── add_edit_product_screen.dart     # UPDATED - Auto-assign user_id
│   │   │   │   └── widgets/
│   │   │   │       ├── product_card.dart
│   │   │   │       ├── product_search_bar.dart
│   │   │   │       └── category_filter_chips.dart
│   │   │   │
│   │   │   ├── scanner/
│   │   │   │   ├── qr_scanner_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── scanner_overlay.dart
│   │   │   │       └── manual_code_input.dart
│   │   │   │
│   │   │   ├── cart/
│   │   │   │   ├── cart_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── cart_item_tile.dart
│   │   │   │       ├── cart_summary.dart
│   │   │   │       └── quantity_selector.dart
│   │   │   │
│   │   │   ├── payment/
│   │   │   │   ├── payment_screen.dart              # UPDATED - User's payment QR
│   │   │   │   ├── payment_success_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── payment_qr_display.dart
│   │   │   │       ├── payment_method_selector.dart
│   │   │   │       └── amount_display.dart
│   │   │   │
│   │   │   ├── receipt/
│   │   │   │   ├── receipt_screen.dart              # UPDATED - User shop details
│   │   │   │   ├── receipt_preview_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── receipt_header.dart          # UPDATED - User shop info
│   │   │   │       ├── receipt_items_list.dart
│   │   │   │       └── receipt_footer.dart
│   │   │   │
│   │   │   ├── reports/
│   │   │   │   ├── personal_reports_screen.dart     # UPDATED - Personal analytics
│   │   │   │   ├── sales_report_screen.dart         # UPDATED - User's sales only
│   │   │   │   ├── inventory_report_screen.dart     # UPDATED - User's inventory
│   │   │   │   └── widgets/
│   │   │   │       ├── personal_chart.dart          # NEW - Personal analytics
│   │   │   │       ├── report_filter.dart
│   │   │   │       └── report_summary_card.dart
│   │   │   │
│   │   │   ├── inventory/
│   │   │   │   ├── inventory_screen.dart            # UPDATED - User's inventory only
│   │   │   │   ├── stock_adjustment_screen.dart
│   │   │   │   ├── inventory_logs_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── inventory_item_card.dart
│   │   │   │       ├── stock_level_indicator.dart
│   │   │   │       └── adjustment_form.dart
│   │   │   │
│   │   │   └── settings/
│   │   │       ├── settings_screen.dart             # UPDATED - User preferences
│   │   │       ├── account_settings_screen.dart     # NEW
│   │   │       ├── backup_restore_screen.dart
│   │   │       └── widgets/
│   │   │           ├── setting_tile.dart
│   │   │           ├── account_info_card.dart       # NEW
│   │   │           └── backup_options.dart
│   │   │
│   │   ├── widgets/
│   │   │   ├── common/
│   │   │   │   ├── custom_app_bar.dart
│   │   │   │   ├── user_avatar.dart                 # NEW - User profile picture
│   │   │   │   ├── loading_widget.dart
│   │   │   │   ├── error_widget.dart
│   │   │   │   ├── empty_state_widget.dart
│   │   │   │   ├── custom_button.dart
│   │   │   │   ├── custom_text_field.dart
│   │   │   │   └── confirmation_dialog.dart
│   │   │   │
│   │   │   └── navigation/
│   │   │       ├── bottom_nav_bar.dart
│   │   │       ├── drawer_menu.dart                 # UPDATED - User info in drawer
│   │   │       └── auth_wrapper.dart                # NEW - Route protection
│   │   │
│   │   └── providers/
│   │       ├── auth_provider.dart                   # NEW - Authentication state
│   │       ├── user_provider.dart                   # NEW - User profile state
│   │       ├── cart_provider.dart                   # UPDATED - User-scoped cart
│   │       ├── product_provider.dart                # UPDATED - User's products only
│   │       ├── sale_provider.dart                   # UPDATED - User's sales only
│   │       ├── inventory_provider.dart              # UPDATED - User's inventory
│   │       ├── theme_provider.dart
│   │       └── settings_provider.dart               # UPDATED - User preferences
│   │
│   └── routes/
│       └── app_router.dart                          # UPDATED - Auth-protected routes
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── default_avatar.png                       # NEW - Default user avatar
│   │   ├── placeholder_product.png
│   │   └── icons/
│   │
│   └── data/
│       └── sample_products.json                     # UPDATED - Include user_id samples
│
├── pubspec.yaml                                     # UPDATED - Added crypto dependency
├── README.md
└── .gitignore
```

---

## 🎨 Color Palette & Design System
*(Same as original - no changes needed)*

### 🛍️ Grocery Shop UI Kit – Full Color Palette

#### ✅ **Primary Colors**
| **Color Name** | **Hex Code** | **Usage** |
|----------------|--------------|-----------|
| Bright Yellow | `#FFC928` | Main background, discounts, highlights |
| Dark Blue | `#1E3A8A` | Header, titles, primary CTA background |
| White | `#FFFFFF` | Card backgrounds, screen background |

#### 🌈 **Secondary / Accent Colors**
| **Color Name** | **Hex Code** | **Usage** |
|----------------|--------------|-----------|
| Light Gray | `#F5F5F5` | Card background, borders, input backgrounds |
| Orange | `#FFA500` | Tags, highlight buttons, discount banners |
| Green | `#90C659` | Success status, organic tags |
| Soft Blue | `#3B82F6` | Hyperlinks, small price tags |
| Black / Dark Gray | `#1F2937` | Primary text, labels |

### Flutter Color Constants Implementation
```dart
// lib/core/constants/app_colors.dart
class AppColors {
  // Primary Colors
  static const Color primaryYellow = Color(0xFFFFC928);
  static const Color primaryDarkBlue = Color(0xFF1E3A8A);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  
  // Secondary/Accent Colors
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color accentOrange = Color(0xFFFFA500);
  static const Color successGreen = Color(0xFF90C659);
  static const Color softBlue = Color(0xFF3B82F6);
  static const Color textDarkGray = Color(0xFF1F2937);
  
  // Status Colors
  static const Color errorRed = Color(0xFFDC2626);
  static const Color warningYellow = Color(0xFFFBBF24);
  static const Color infoBlue = Color(0xFF3B82F6);
}
```

---

## 🏗️ Architecture & Implementation

### App Architecture with User Management

The architecture now includes **Authentication Layer** and **User Context**:

```
+---------------------------+
| Presentation Layer        | ← UI screens & widgets
| - LoginScreen             |
| - DashboardScreen         |
| - ProfileScreen           |
+---------------------------+
            ↓
+---------------------------+
| Authentication Layer      | ← NEW - User session management
| - AuthProvider            |
| - SessionManager          |
+---------------------------+
            ↓
+---------------------------+
| Business Logic Layer      | ← Controllers / Providers (User-scoped)
| - UserProvider            |
| - ProductProvider         |
| - SaleProvider            |
+---------------------------+
            ↓
+---------------------------+
| Data Layer               | ← SQLite + Repositories (User-filtered)
| - UserDAO                |
| - ProductDAO             |
| - SaleDAO                |
+---------------------------+
```

### Dependencies (Updated pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.5
  
  # Database
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # Authentication & Security
  crypto: ^3.0.3          # NEW - For password hashing
  bcrypt: ^1.1.3          # NEW - Advanced password hashing
  
  # QR Code
  mobile_scanner: ^3.5.2
  qr_flutter: ^4.1.0
  
  # PDF Generation
  pdf: ^3.10.4
  printing: ^5.11.0
  
  # File handling
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
  
  # UI Components
  cupertino_icons: ^1.0.2
  flutter_svg: ^2.0.7
  cached_network_image: ^3.3.0
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.1.0
  share_plus: ^7.2.1
  url_launcher: ^6.2.1
  
  # Charts (for reports)
  fl_chart: ^0.65.0
```

---

## 🔐 Authentication & User Management

### Key Changes Needed in Existing Files:

#### **What You Need to Add:**

1. **New Files to Create:**
   - `lib/data/models/user.dart` - User model with Thai Baht default
   - `lib/data/database/dao/user_dao.dart` - User database operations
   - `lib/core/services/auth_service.dart` - Authentication logic
   - `lib/core/utils/session_manager.dart` - User session management
   - `lib/core/utils/encryption_helper.dart` - Password hashing
   - `lib/presentation/pages/auth/` folder - Login/signup screens
   - `lib/presentation/providers/auth_provider.dart` - Authentication state

2. **Existing Files to Update:**
   - All DAO classes: Add user_id filtering to every method
   - All Repository classes: Add user context to operations
   - All Provider classes: Filter data by logged-in user
   - All UI screens: Show only user-specific data
   - Database helper: Add users table creation
   - App router: Add authentication protection

#### **Currency Configuration (Thai Baht Default):**

In your user model and currency formatter:
- Default currency: `THB` (Thai Baht)
- Currency symbol: `฿` 
- Supported currencies: `THB`, `USD`
- User can change currency in profile settings

#### **Critical Changes Required:**

**1. Every Database Query Must Filter by User:**
- Products: `WHERE user_id = ?`
- Sales: `WHERE user_id = ?`  
- Inventories: `WHERE user_id = ?`

**2. Every Repository Method Needs User Context:**
- Get current user ID from session manager
- Pass user_id to all DAO operations
- Throw authentication error if user not logged in

**3. Every UI Screen Shows Only User Data:**
- Dashboard: Personal sales summary
- Products: User's products only
- Reports: User's analytics only
- Receipts: User's shop information

**4. Route Protection:**
- Check authentication before accessing any main screen
- Redirect to login if not authenticated
- Auto-redirect to dashboard if already logged in

---

## ✅ Getting Started Checklist (Updated)

### Phase 1: Database & User Setup
- [ ] Add users table to database schema
- [ ] Update existing tables to include user_id column
- [ ] Add foreign key constraints for user relationships
- [ ] Update database indexes to include user_id
- [ ] Set default currency to THB in users table

### Phase 2: Authentication Foundation
- [ ] Create user model with THB default currency
- [ ] Implement password hashing utility
- [ ] Create user DAO for database operations
- [ ] Build authentication service
- [ ] Implement session manager for user context
- [ ] Create login and signup screens

### Phase 3: Update Existing Features
- [ ] Update all DAO methods to filter by user_id
- [ ] Modify all repository classes to use user context
- [ ] Update all provider classes for user-scoped data
- [ ] Modify UI screens to show only user's data
- [ ] Update receipt generation with user's shop details
- [ ] Configure payment QR with user's payment info

### Phase 4: User Experience
- [ ] Create user profile and shop settings screens
- [ ] Update dashboard to show personal analytics
- [ ] Add user welcome header and branding
- [ ] Implement route protection and auth guards
- [ ] Add user avatar and profile management
- [ ] Configure Thai Baht currency