// FILE: lib/core/translations.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _values = {
    'en': {
      // General & Common
      'app_name': 'Jame',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'confirm': 'Confirm',
      'search': 'Search',
      'back': 'Back',
      'next': 'Next',
      'success': 'Success',
      'error': 'Error',
      'warning': 'Warning',
      'loading': 'Loading...',
      'no_data': 'No data available',
      'all': 'All',
      'view_all': 'View All',
      'currency_symbol': '\$',

      // Navigation
      'nav_dashboard': 'Dashboard',
      'nav_products': 'Products',
      'nav_scanner': 'Scanner',
      'nav_cart': 'Cart',
      'nav_payment': 'Payment',
      'nav_receipt': 'Receipt',
      'nav_reports': 'Reports',
      'nav_profile': 'Profile',
      'nav_notifications': 'Notifications',

      // Authentication
      'login_title': 'Sign In',
      'signup_title': 'Create Account',
      'forgot_password_title': 'Forgot Password',
      'welcome_back': 'Welcome Back',
      'sign_in_to_continue': 'Sign in to continue to your shop',
      'create_new_account': 'Create a new shop account',
      'email': 'Email',
      'email_hint': 'Enter your email address',
      'password': 'Password',
      'password_hint': 'Enter your password',
      'confirm_password': 'Confirm Password',
      'confirm_password_hint': 'Re-enter your password',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'username': 'Username',
      'shop_name': 'Shop Name',
      'shop_name_hint': 'Enter your shop name',
      'shop_phone': 'Phone Number',
      'shop_address': 'Shop Address',
      'forgot_password_prompt': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'send_reset_code': 'Send Reset Link',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'remember_me': 'Remember me',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'logout': 'Sign Out',
      'logout_confirm': 'Are you sure you want to sign out?',

      // Auth Validation Messages
      'email_required': 'Please enter your email',
      'email_invalid': 'Please enter a valid email address',
      'password_required': 'Please enter your password',
      'password_short': 'Password must be at least 6 characters',
      'passwords_not_match': 'Passwords do not match',
      'shop_name_required': 'Please enter your shop name',

      // Dashboard
      'today_sales': "Today's Sales",
      'today_orders': "Today's Orders",
      'total_revenue': 'Total Revenue',
      'weekly_sales': 'Weekly Sales',
      'monthly_sales': 'Monthly Sales',
      'top_selling': 'Top Selling Products',
      'low_stock_alert': 'Low Stock Alert',
      'quick_actions': 'Quick Actions',
      'new_sale': 'New Sale',
      'scan_product': 'Scan Barcode',
      'add_product': 'Add Product',
      'sales_history': 'Sales History',
      'items_sold': 'items sold',

      // Products & Inventory
      'product_list': 'Product List',
      'add_new_product': 'Add New Product',
      'edit_product': 'Edit Product',
      'product_name': 'Product Name',
      'product_name_hint': 'Enter product name',
      'barcode': 'Barcode',
      'barcode_hint': 'Scan or enter barcode',
      'price': 'Price',
      'cost_price': 'Cost Price',
      'stock_quantity': 'Stock Quantity',
      'category': 'Category',
      'select_category': 'Select Category',
      'in_stock': 'In Stock',
      'out_of_stock': 'Out of Stock',
      'low_stock': 'Low Stock',
      'delete_product_confirm': 'Are you sure you want to delete this product?',
      'product_saved': 'Product saved successfully',
      'product_deleted': 'Product deleted successfully',

      // Cart & POS
      'shopping_cart': 'Shopping Cart',
      'cart_empty': 'Your cart is empty',
      'cart_empty_sub': 'Scan barcodes or add products to start selling',
      'items_in_cart': 'items in cart',
      'subtotal': 'Subtotal',
      'discount': 'Discount',
      'tax': 'Tax',
      'total': 'Total',
      'total_amount': 'Total Amount',
      'checkout': 'Proceed to Checkout',
      'clear_cart': 'Clear Cart',
      'clear_cart_confirm': 'Clear all items from the cart?',
      'quantity': 'Qty',
      'unit_price': 'Unit Price',

      // Payment
      'payment_method': 'Payment Method',
      'cash': 'Cash',
      'qr_payment': 'QR Code / Bank Transfer',
      'amount_received': 'Amount Received',
      'change': 'Change',
      'exact_amount': 'Exact Amount',
      'confirm_payment': 'Complete Payment',
      'payment_success': 'Payment Completed Successfully',
      'insufficient_amount': 'Received amount is less than total',

      // Receipt
      'receipt_title': 'Receipt',
      'receipt_no': 'Receipt No',
      'date': 'Date',
      'time': 'Time',
      'cashier': 'Cashier',
      'print_receipt': 'Print Receipt',
      'share_receipt': 'Share',
      'new_transaction': 'Next Sale',
      'thank_you': 'Thank you for your purchase!',

      // Reports
      'reports_title': 'Sales Reports',
      'overview': 'Overview',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'custom_range': 'Custom Date',
      'total_sales': 'Total Sales',
      'total_transactions': 'Transactions',
      'average_ticket': 'Average Sale',

      // Profile & Settings
      'profile_title': 'Shop Profile & Settings',
      'personal_info': 'Personal Information',
      'shop_info': 'Shop Information',
      'settings': 'Settings',
      'language': 'Language',
      'language_en': 'English',
      'language_km': 'Khmer (ភាសាខ្មែរ)',
      'dark_mode': 'Dark Mode',
      'currency': 'Currency',
      'save_changes': 'Save Changes',
      'profile_updated': 'Profile updated successfully',
    },

    'km': {
      // General & Common
      'app_name': 'Jame',
      'ok': 'យល់ព្រម',
      'cancel': 'បោះបង់',
      'save': 'រក្សាទុក',
      'delete': 'លុប',
      'edit': 'កែប្រែ',
      'add': 'បន្ថែម',
      'close': 'បិទ',
      'confirm': 'បញ្ជាក់',
      'search': 'ស្វែងរក',
      'back': 'ត្រឡប់ក្រោយ',
      'next': 'បន្ទាប់',
      'success': 'ជោគជ័យ',
      'error': 'កំហុស',
      'warning': 'ការព្រមាន',
      'loading': 'កំពុងដំណើរការ...',
      'no_data': 'មិនមានទិន្នន័យទេ',
      'all': 'ទាំងអស់',
      'view_all': 'មើលទាំងអស់',
      'currency_symbol': '\$',

      // Navigation
      'nav_dashboard': 'ផ្ទាំងគ្រប់គ្រង',
      'nav_products': 'ទំនិញ',
      'nav_scanner': 'ស្កេន',
      'nav_cart': 'កន្ត្រក',
      'nav_payment': 'ទូទាត់ប្រាក់',
      'nav_receipt': 'វិក្កយបត្រ',
      'nav_reports': 'របាយការណ៍',
      'nav_profile': 'គណនី/ព័ត៌មាន',
      'nav_notifications': 'ការជូនដំណឹង',

      // Authentication
      'login_title': 'ចូលប្រើប្រាស់',
      'signup_title': 'បង្កើតគណនីថ្មី',
      'forgot_password_title': 'ភ្លេចពាក្យសម្ងាត់',
      'welcome_back': 'សូមស្វាគមន៍មកវិញ',
      'sign_in_to_continue': 'សូមចូលប្រើដើម្បីគ្រប់គ្រងហាងរបស់អ្នក',
      'create_new_account': 'បង្កើតគណនីហាងថ្មី',
      'email': 'អ៊ីមែល',
      'email_hint': 'បញ្ចូលអ៊ីមែលរបស់អ្នក',
      'password': 'ពាក្យសម្ងាត់',
      'password_hint': 'បញ្ចូលពាក្យសម្ងាត់',
      'confirm_password': 'បញ្ជាក់ពាក្យសម្ងាត់',
      'confirm_password_hint': 'បញ្ចូលពាក្យសម្ងាត់ម្តងទៀត',
      'first_name': 'នាមខ្លួន',
      'last_name': 'នាមត្រកូល',
      'username': 'ឈ្មោះអ្នកប្រើ',
      'shop_name': 'ឈ្មោះហាង',
      'shop_name_hint': 'បញ្ចូលឈ្មោះហាងរបស់អ្នក',
      'shop_phone': 'លេខទូរស័ព្ទ',
      'shop_address': 'អាសយដ្ឋានហាង',
      'forgot_password_prompt': 'ភ្លេចពាក្យសម្ងាត់?',
      'reset_password': 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ',
      'send_reset_code': 'ផ្ញើតំណភ្ជាប់កំណត់ឡើងវិញ',
      'dont_have_account': 'មិនទាន់មានគណនីមែនទេ?',
      'already_have_account': 'មានគណនីរួចហើយ?',
      'remember_me': 'ចងចាំខ្ញុំក្នុងប្រព័ន្ធ',
      'sign_in': 'ចូលប្រព័ន្ធ',
      'sign_up': 'ចុះឈ្មោះ',
      'logout': 'ចាកចេញ',
      'logout_confirm': 'តើអ្នកពិតជាចង់ចាកចេញមែនទេ?',

      // Auth Validation Messages
      'email_required': 'សូមបញ្ចូលអ៊ីមែល',
      'email_invalid': 'ទម្រង់អ៊ីមែលមិនត្រឹមត្រូវទេ',
      'password_required': 'សូមបញ្ចូលពាក្យសម្ងាត់',
      'password_short': 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ',
      'passwords_not_match': 'ពាក្យសម្ងាត់ទាំងពីរមិនដូចគ្នាទេ',
      'shop_name_required': 'សូមបញ្ចូលឈ្មោះហាងរបស់អ្នក',

      // Dashboard
      'today_sales': 'ការលក់ថ្ងៃនេះ',
      'today_orders': 'ការបញ្ជាទិញថ្ងៃនេះ',
      'total_revenue': 'ចំណូលសរុប',
      'weekly_sales': 'ការលក់ប្រចាំសប្តាហ៍',
      'monthly_sales': 'ការលក់ប្រចាំខែ',
      'top_selling': 'ទំនិញលក់ដាច់បំផុត',
      'low_stock_alert': 'ការជូនដំណឹងទំនិញជិតអស់ពីស្តុក',
      'quick_actions': 'ផ្លូវកាត់រហ័ស',
      'new_sale': 'ការលក់ថ្មី',
      'scan_product': 'ស្កេនបាកូដ',
      'add_product': 'បន្ថែមទំនិញ',
      'sales_history': 'ប្រវត្តិការលក់',
      'items_sold': 'ទំនិញបានលក់',

      // Products & Inventory
      'product_list': 'បញ្ជីទំនិញ',
      'add_new_product': 'បន្ថែមទំនិញថ្មី',
      'edit_product': 'កែប្រែទំនិញ',
      'product_name': 'ឈ្មោះទំនិញ',
      'product_name_hint': 'បញ្ចូលឈ្មោះទំនិញ',
      'barcode': 'បាកូដ',
      'barcode_hint': 'ស្កេន ឬបញ្ចូលលេខបាកូដ',
      'price': 'តម្លៃលក់',
      'cost_price': 'តម្លៃដើម',
      'stock_quantity': 'ចំនួនក្នុងស្តុក',
      'category': 'ប្រភេទ',
      'select_category': 'ជ្រើសរើសប្រភេទ',
      'in_stock': 'មានក្នុងស្តុក',
      'out_of_stock': 'អស់ពីស្តុក',
      'low_stock': 'ជិតអស់ស្តុក',
      'delete_product_confirm': 'តើអ្នកពិតជាចង់លុបទំនិញនេះមែនទេ?',
      'product_saved': 'រក្សាទុកទំនិញបានជោគជ័យ',
      'product_deleted': 'បានលុបទំនិញរួចរាល់',

      // Cart & POS
      'shopping_cart': 'កន្ត្រកទំនិញ',
      'cart_empty': 'កន្ត្រកទទេស្អាត',
      'cart_empty_sub': 'ស្កេនបាកូដ ឬជ្រើសរើសទំនិញដើម្បីចាប់ផ្តើមលក់',
      'items_in_cart': 'ទំនិញក្នុងកន្ត្រក',
      'subtotal': 'សរុបបណ្តោះអាសន្ន',
      'discount': 'បញ្ចុះតម្លៃ',
      'tax': 'ពន្ធ',
      'total': 'សរុប',
      'total_amount': 'ទឹកប្រាក់សរុប',
      'checkout': 'គិតលុយ',
      'clear_cart': 'សម្អាតកន្ត្រក',
      'clear_cart_confirm': 'តើអ្នកចង់លុបទំនិញទាំងអស់ចេញពីកន្ត្រក?',
      'quantity': 'ចំនួន',
      'unit_price': 'តម្លៃរាយ',

      // Payment
      'payment_method': 'វិធីសាស្ត្រទូទាត់',
      'cash': 'សាច់ប្រាក់សុទ្ធ',
      'qr_payment': 'ស្កេន QR កូដ / ធនាគារ',
      'amount_received': 'ប្រាក់ទទួលបាន',
      'change': 'ប្រាក់អាប់',
      'exact_amount': 'គ្រប់ចំនួន',
      'confirm_payment': 'បញ្ចប់ការទូទាត់',
      'payment_success': 'ការទូទាត់បានជោគជ័យ',
      'insufficient_amount': 'ទឹកប្រាក់ទទួលបានមិនទាន់គ្រប់ចំនួននៅឡើយ',

      // Receipt
      'receipt_title': 'វិក្កយបត្រ',
      'receipt_no': 'លេខវិក្កយបត្រ',
      'date': 'កាលបរិច្ឆេទ',
      'time': 'ម៉ោង',
      'cashier': 'អ្នកគិតលុយ',
      'print_receipt': 'បោះពុម្ពវិក្កយបត្រ',
      'share_receipt': 'ចែករំលែក',
      'new_transaction': 'ការលក់បន្ទាប់',
      'thank_you': 'សូមអរគុណចំពោះការគាំទ្រ!',

      // Reports
      'reports_title': 'របាយការណ៍ការលក់',
      'overview': 'ទិដ្ឋភាពទូទៅ',
      'daily': 'ប្រចាំថ្ងៃ',
      'weekly': 'ប្រចាំសប្តាហ៍',
      'monthly': 'ប្រចាំខែ',
      'custom_range': 'ជ្រើសកាលបរិច្ឆេទ',
      'total_sales': 'ការលក់សរុប',
      'total_transactions': 'ចំនួនប្រតិបត្តិការ',
      'average_ticket': 'មធ្យមភាគការលក់',

      // Profile & Settings
      'profile_title': 'ព័ត៌មានហាង & ការកំណត់',
      'personal_info': 'ព័ត៌មានផ្ទាល់ខ្លួន',
      'shop_info': 'ព័ត៌មានហាង',
      'settings': 'ការកំណត់',
      'language': 'ភាសា',
      'language_en': 'អង់គ្លេស (English)',
      'language_km': 'ខ្មែរ (Khmer)',
      'dark_mode': 'ទម្រង់ងងឹត',
      'currency': 'រូបិយប័ណ្ណ',
      'save_changes': 'រក្សាទុកការផ្លាស់ប្តូរ',
      'profile_updated': 'បានកែប្រែព័ត៌មានជោគជ័យ',
    },
  };

  static String get(String key, String languageCode) {
    final lang = (languageCode == 'km') ? 'km' : 'en';
    return _values[lang]?[key] ?? _values['en']?[key] ?? key;
  }
}

// Extension to easily call context.tr('key') from any widget
extension TranslationExtension on BuildContext {
  String tr(String key) {
    try {
      final settings = Provider.of<SettingsProvider>(this, listen: true);
      return AppTranslations.get(key, settings.language);
    } catch (_) {
      return AppTranslations.get(key, 'en');
    }
  }

  // Non-listening version for callbacks / event handlers
  String trRead(String key) {
    try {
      final settings = Provider.of<SettingsProvider>(this, listen: false);
      return AppTranslations.get(key, settings.language);
    } catch (_) {
      return AppTranslations.get(key, 'en');
    }
  }
}
