import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../core/translations.dart';
import '../widgets/language_switch_button.dart';
import '../models/product.dart';
import '../core/constants.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _surface = Color(0xFFF3F4F6);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _muted = Color(0xFF6B7280);

  String _money(num value) =>
      '${AppConstants.currencySymbol}${NumberFormat('#,##0.00').format(value)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, app, child) {
            return Column(
              children: [
                _buildTopBar(app),
                Expanded(
                  child: app.cartItems.isEmpty
                      ? _buildEmptyCart()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Wide screens: items on the left, sticky order summary on the right.
                            if (constraints.maxWidth >= 900) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildItemList(app, 24)),
                                  SizedBox(
                                    width: 400,
                                    child: _buildSummaryPanel(app),
                                  ),
                                ],
                              );
                            }
                            // Phones / narrow windows: items with a pay bar pinned to the bottom.
                            return Column(
                              children: [
                                Expanded(child: _buildItemList(app, 16)),
                                _buildBottomBar(app),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ top bar

  Widget _buildTopBar(AppProvider app) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppConstants.primaryDarkBlue,
            iconSize: 26,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.tr('shopping_cart'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppConstants.primaryDarkBlue,
              ),
            ),
          ),
          if (app.cartItems.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryYellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${app.cartItemCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ),
          ],
          const Spacer(),
          const LanguageSwitchButton(compact: true),
          if (app.cartItems.isNotEmpty) ...[
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => _showClearCartDialog(app),
              icon: const Icon(Icons.delete_sweep_rounded, size: 20),
              label: Text(AppTranslations.t('ui_clear_cart')),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.errorRed,
                minimumSize: const Size(48, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------- item list

  Widget _buildItemList(AppProvider app, double padding) {
    return ListView.separated(
      padding: EdgeInsets.all(padding),
      itemCount: app.cartItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildItemTile(app, app.cartItems[index]),
    );
  }

  Widget _buildItemTile(AppProvider app, CartItem item) {
    final stock = item.product.quantity;
    final over = item.quantity > stock;
    final atMax = item.quantity == stock;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: over ? AppConstants.errorRed : _border,
          width: over ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(item.product),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppConstants.textDarkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_money(item.product.price)} / ${item.product.unit}',
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _money(item.totalPrice),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.primaryDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStepper(app, item),
              const SizedBox(width: 12),
              if (over || atMax)
                Flexible(
                  child: _stockNote(over: over, stock: stock),
                ),
              const Spacer(),
              IconButton(
                tooltip: AppTranslations.t('ui_delete'),
                onPressed: () => _showRemoveItemDialog(app, item),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppConstants.errorRed,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockNote({required bool over, required int stock}) {
    final color = over ? AppConstants.errorRed : const Color(0xFFB45309);
    final bg = over ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              over
                  ? AppTranslations.t('ui_cart_in_stock_n', [stock])
                  : AppTranslations.t('ui_cart_max_reached'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(AppProvider app, CartItem item) {
    final canDecrease = item.quantity > 1;
    final canIncrease = item.quantity < item.product.quantity;

    Widget roundButton(IconData icon, VoidCallback? onTap) => SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        iconSize: 24,
        color: AppConstants.primaryDarkBlue,
        disabledColor: const Color(0xFFD1D5DB),
      ),
    );

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          roundButton(
            Icons.remove_rounded,
            canDecrease
                ? () => _updateCartItemQuantity(app, item, item.quantity - 1)
                : null,
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _editQuantity(app, item),
            child: Container(
              constraints: const BoxConstraints(minWidth: 48),
              height: 48,
              alignment: Alignment.center,
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.textDarkGray,
                ),
              ),
            ),
          ),
          roundButton(
            Icons.add_rounded,
            canIncrease
                ? () => _updateCartItemQuantity(app, item, item.quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }

  /// Tap the quantity to type it (fast for bulk sales).
  void _editQuantity(AppProvider app, CartItem item) {
    final controller = TextEditingController(text: '${item.quantity}');
    final stock = item.product.quantity;
    void apply(BuildContext dialogContext) {
      final value = int.tryParse(controller.text.trim()) ?? item.quantity;
      final int clamped = value.clamp(1, stock < 1 ? 1 : stock).toInt();
      Navigator.pop(dialogContext);
      if (clamped != item.quantity) _updateCartItemQuantity(app, item, clamped);
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppTranslations.t('ui_cart_edit_qty')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          onSubmitted: (_) => apply(dialogContext),
          decoration: InputDecoration(
            helperText: AppTranslations.t('ui_cart_in_stock_n', [stock]),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppTranslations.t('ui_cancel')),
          ),
          FilledButton(
            onPressed: () => apply(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.primaryDarkBlue,
            ),
            child: Text(AppTranslations.t('ui_cart_apply')),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- summary (wide/narrow)

  Widget _payButton(
    AppProvider app, {
    required String label,
    double height = 60,
  }) {
    final enabled = _canProceedToPayment(app);
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: enabled ? _proceedToPayment : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.primaryYellow,
          foregroundColor: AppConstants.primaryDarkBlue,
          disabledBackgroundColor: Colors.white24,
          disabledForegroundColor: Colors.white54,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }

  Widget _stockBlocker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppConstants.primaryYellow,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppTranslations.t('ui_cart_fix_stock'),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(AppProvider app) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppConstants.primaryDarkBlue,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppTranslations.t('ui_order_summary'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _summaryRow(
              AppTranslations.t('ui_cart_n_lines', [app.cartItems.length]),
              '',
            ),
            _summaryRow(
              AppTranslations.t('ui_cart_n_pieces', [app.cartItemCount]),
              '',
            ),
            _summaryRow(
              AppTranslations.t('ui_cart_subtotal'),
              _money(app.cartTotal),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white24, height: 1),
            ),
            Text(
              AppTranslations.t('ui_cart_total_due'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _money(app.cartTotal),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_hasStockWarnings(app)) ...[
              _stockBlocker(),
              const SizedBox(height: 12),
            ],
            _payButton(
              app,
              label: AppTranslations.t('ui_cart_pay_now', [
                _money(app.cartTotal),
              ]),
              height: 64,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _secondaryAction(
                    Icons.qr_code_scanner_rounded,
                    AppTranslations.t('ui_scan'),
                    AppConstants.scannerRoute,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _secondaryAction(
                    Icons.inventory_2_rounded,
                    AppTranslations.t('ui_products'),
                    AppConstants.productsRoute,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryAction(IconData icon, String label, String route) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white38),
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildBottomBar(AppProvider app) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppConstants.primaryDarkBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasStockWarnings(app)) ...[
            _stockBlocker(),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppTranslations.t('ui_cart_n_pieces', [
                        app.cartItemCount,
                      ]),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _money(app.cartTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _payButton(
                app,
                label: AppTranslations.t('ui_payment'),
                height: 56,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppConstants.primaryDarkBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppConstants.primaryDarkBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppTranslations.t('ui_your_cart_is_empty'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.t('ui_start_adding_products_by_scanning_a'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppConstants.scannerRoute),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(AppTranslations.t('ui_scan_qr')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryDarkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppConstants.productsRoute,
                    ),
                    icon: const Icon(Icons.inventory_2),
                    label: Text(AppTranslations.t('ui_choose_products')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryDarkBlue,
                      side: const BorderSide(
                        color: AppConstants.primaryDarkBlue,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCartItemQuantity(
    AppProvider app,
    CartItem cartItem,
    int newQuantity,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (auth.currentUser?.id != null) {
        await app.updateCartItemQuantityWithPersistence(
          auth.currentUser!.id!,
          cartItem.product.id!,
          newQuantity,
        );
      } else {
        app.updateCartItemQuantity(cartItem.product.id!, newQuantity);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  void _showRemoveItemDialog(AppProvider app, CartItem cartItem) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.t('ui_remove_from_cart')),
        content: Text(
          AppTranslations.t('ui_do_you_want_to_remove_from', [
            cartItem.product.name,
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.t('ui_cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              // Store the ScaffoldMessenger state at the very beginning to ensure we have a valid reference
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                if (auth.currentUser?.id != null) {
                  await app.removeFromCartWithPersistence(
                    auth.currentUser!.id!,
                    cartItem.product.id!,
                  );
                } else {
                  app.removeFromCart(cartItem.product.id!);
                }
              } catch (error) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(error.toString()),
                    backgroundColor: AppConstants.errorRed,
                  ),
                );
                return;
              }
              Navigator.pop(context);

              // Use a delayed callback to show snackbar after dialog is completely dismissed
              Future.delayed(Duration(milliseconds: 50), () {
                // Show snackbar using the stored scaffold messenger reference
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      AppTranslations.t('ui_removed_from_the_cart', [
                        cartItem.product.name,
                      ]),
                    ),
                    backgroundColor: AppConstants.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppTranslations.t('ui_delete')),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(AppProvider app) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.t('ui_clear_cart')),
        content: Text(AppTranslations.t('ui_do_you_want_to_remove_all')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.t('ui_cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              // Store the ScaffoldMessenger state at the very beginning to ensure we have a valid reference
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                if (auth.currentUser?.id != null) {
                  await app.clearCartWithPersistence(auth.currentUser!.id!);
                } else {
                  app.clearCart();
                }
              } catch (error) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(error.toString()),
                    backgroundColor: AppConstants.errorRed,
                  ),
                );
                return;
              }
              Navigator.pop(context);

              // Use a delayed callback to show snackbar after dialog is completely dismissed
              Future.delayed(Duration(milliseconds: 100), () {
                // Show snackbar using the stored scaffold messenger reference
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(AppTranslations.t('ui_cart_cleared')),
                    backgroundColor: AppConstants.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppTranslations.t('ui_clear_cart')),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppConstants.primaryDarkBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: product.image != null && product.image!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Log the error for debugging
                  print('Image loading error in cart: $error');
                  return Icon(
                    Icons.inventory_2,
                    color: AppConstants.primaryDarkBlue,
                    size: 24,
                  );
                },
                // Add headers to handle WebP and other formats
                headers: const {'Accept': 'image/*'},
              ),
            )
          : Icon(
              Icons.inventory_2,
              color: AppConstants.primaryDarkBlue,
              size: 24,
            ),
    );
  }

  bool _canProceedToPayment(AppProvider app) {
    if (app.cartItems.isEmpty) return false;

    // Check if any items exceed available stock
    for (var item in app.cartItems) {
      if (item.quantity > item.product.quantity) {
        return false;
      }
    }
    return true;
  }

  bool _hasStockWarnings(AppProvider app) {
    return app.cartItems.any((item) => item.quantity > item.product.quantity);
  }

  void _proceedToPayment() {
    Navigator.pushNamed(context, AppConstants.paymentRoute);
  }
}
