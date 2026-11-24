// FILE: lib/widgets/product_form_dialog.dart
// Add / edit product form with a live product preview.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/translations.dart';
import '../models/product.dart';

/// Values collected by [ProductFormDialog].
class ProductFormValues {
  final String name;
  final String code;
  final double price;
  final int quantity;
  final int lowStock;
  final String unit;
  final String category;
  final String image;

  const ProductFormValues({
    required this.name,
    required this.code,
    required this.price,
    required this.quantity,
    required this.lowStock,
    required this.unit,
    required this.category,
    required this.image,
  });
}

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final String? prefilledCode;
  final List<String> categories;

  /// Opens the image picker; it writes the chosen link/path into the controller.
  final void Function(TextEditingController imageController) onPickImage;

  /// Called with validated values. The caller is responsible for closing the dialog.
  final void Function(ProductFormValues values) onSave;

  const ProductFormDialog({
    Key? key,
    this.product,
    this.prefilledCode,
    required this.categories,
    required this.onPickImage,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  static const List<String> _units = ['pcs', 'kg', 'g', 'L', 'box', 'pack', 'bottle'];
  static const Color _field = Color(0xFFF3F4F6);
  static const Color _muted = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _price;
  late final TextEditingController _qty;
  late final TextEditingController _low;
  late final TextEditingController _unit;
  late final TextEditingController _image;
  String? _category;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _code = TextEditingController(text: p?.code ?? widget.prefilledCode ?? '');
    _price = TextEditingController(text: p == null ? '' : _trimNumber(p.price));
    _qty = TextEditingController(text: p == null ? '' : p.quantity.toString());
    _low = TextEditingController(text: p?.lowStock.toString() ?? '5');
    _unit = TextEditingController(text: p?.unit ?? 'pcs');
    _image = TextEditingController(text: p?.image ?? '');
    _category = (p?.category != null && p!.category!.isNotEmpty) ? p.category : null;
    for (final c in [_name, _price, _qty, _low, _unit, _image]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_name, _code, _price, _qty, _low, _unit, _image]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _trimNumber(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  // ---------------------------------------------------------------- actions

  void _submit() {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    widget.onSave(ProductFormValues(
      name: _name.text.trim(),
      code: _code.text.trim(),
      price: double.tryParse(_price.text.trim()) ?? 0,
      quantity: int.tryParse(_qty.text.trim()) ?? 0,
      lowStock: int.tryParse(_low.text.trim()) ?? 5,
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      category: _category ?? '',
      image: _image.text.trim(),
    ));
  }

  void _step(TextEditingController c, int delta) {
    final current = int.tryParse(c.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    c.text = next.toString();
    c.selection = TextSelection.collapsed(offset: c.text.length);
  }

  // ----------------------------------------------------------------- styles

  InputDecoration _dec(String label, {String? hint, String? prefixText, Widget? prefix, Widget? suffix}) {
    OutlineInputBorder border(Color color, [double width = 0]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: _field,
      labelStyle: const TextStyle(color: _muted),
      floatingLabelStyle: const TextStyle(color: AppConstants.primaryDarkBlue, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(AppConstants.primaryDarkBlue, 1.6),
      errorBorder: border(AppConstants.errorRed, 1.2),
      focusedErrorBorder: border(AppConstants.errorRed, 1.6),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppConstants.textDarkGray,
          ),
        ),
      );

  // ------------------------------------------------------------- image tile

  bool get _hasImage => _image.text.trim().isNotEmpty;
  bool get _isNetworkImage {
    final u = _image.text.trim().toLowerCase();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  Widget _imagePlaceholder({required bool attached}) {
    return Container(
      color: _field,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attached ? Icons.check_circle_rounded : Icons.add_photo_alternate_outlined,
            size: 36,
            color: attached ? AppConstants.successGreen : _muted,
          ),
          const SizedBox(height: 6),
          Text(
            attached ? AppTranslations.t('ui_pf_photo_attached') : AppTranslations.t('ui_pf_add_photo'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _imageTile(double size) {
    Widget content;
    if (_isNetworkImage) {
      content = Image.network(
        _image.text.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(attached: false),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                color: _field,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      );
    } else {
      content = _imagePlaceholder(attached: _hasImage);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => widget.onPickImage(_image),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(20), child: content),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryDarkBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _hasImage ? AppTranslations.t('ui_pf_change_photo') : AppTranslations.t('ui_upload_image'),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- preview

  Widget _stockBadge() {
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    final low = int.tryParse(_low.text.trim()) ?? 0;
    late final String label;
    late final Color bg;
    late final Color fg;
    if (_qty.text.trim().isEmpty) {
      label = AppTranslations.t('ui_pf_stock_not_set');
      bg = _field;
      fg = _muted;
    } else if (qty <= 0) {
      label = AppTranslations.t('ui_out_of_stock');
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
    } else if (qty <= low) {
      label = AppTranslations.t('ui_low_stock');
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else {
      label = AppTranslations.t('ui_in_stock');
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
    }
    final unit = _unit.text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _qty.text.trim().isEmpty ? label : '$label · $qty $unit',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewText() {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    final unit = _unit.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name.isEmpty ? AppTranslations.t('ui_product_name') : name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: name.isEmpty ? const Color(0xFF9CA3AF) : AppConstants.textDarkGray,
          ),
        ),
        if (_category != null) ...[
          const SizedBox(height: 2),
          Text(
            AppTranslations.label(_category!),
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                '${AppConstants.currencySymbol}${NumberFormat('#,##0.00').format(price ?? 0)}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: price == null ? const Color(0xFF9CA3AF) : AppConstants.primaryDarkBlue,
                ),
              ),
            ),
            if (unit.isNotEmpty)
              Text(' / $unit', style: const TextStyle(fontSize: 13, color: _muted)),
          ],
        ),
        const SizedBox(height: 10),
        _stockBadge(),
      ],
    );
  }

  Widget _previewPanel({required bool wide}) {
    if (wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imageTile(260),
          if (_hasImage)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: () => _image.clear(),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(AppTranslations.t('ui_pf_remove_photo')),
                style: TextButton.styleFrom(foregroundColor: _muted),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.primaryYellow.withOpacity(0.7)),
            ),
            child: _previewText(),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _imageTile(112),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConstants.primaryYellow.withOpacity(0.7)),
            ),
            child: _previewText(),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- form

  Widget _categoryChips() {
    final items = <String>[...widget.categories];
    if (_category != null && !items.contains(_category)) items.add(_category!);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((c) {
        final selected = c == _category;
        return ChoiceChip(
          label: Text(AppTranslations.label(c)),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _category = selected ? null : c),
          backgroundColor: _field,
          selectedColor: AppConstants.primaryDarkBlue,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppConstants.textDarkGray,
          ),
        );
      }).toList(),
    );
  }

  Widget _stepperField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: validator,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: _dec(
            label,
            prefix: IconButton(
              tooltip: '-1',
              icon: const Icon(Icons.remove_rounded),
              color: AppConstants.primaryDarkBlue,
              onPressed: () => _step(controller, -1),
            ),
            suffix: IconButton(
              tooltip: '+1',
              icon: const Icon(Icons.add_rounded),
              color: AppConstants.primaryDarkBlue,
              onPressed: () => _step(controller, 1),
            ),
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(helper, style: const TextStyle(fontSize: 12, color: _muted)),
          ),
      ],
    );
  }

  Widget _formPanel(bool wide) {
    final priceField = TextFormField(
      controller: _price,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      validator: (v) {
        final n = double.tryParse((v ?? '').trim());
        if (n == null || n < 0) return AppTranslations.t('ui_please_enter_a_valid_price');
        return null;
      },
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: _dec(AppTranslations.t('ui_price'), prefixText: '${AppConstants.currencySymbol} '),
    );

    final unitField = TextFormField(
      controller: _unit,
      decoration: _dec(
        AppTranslations.t('ui_unit_2'),
        suffix: PopupMenuButton<String>(
          tooltip: AppTranslations.t('ui_unit_2'),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppConstants.primaryDarkBlue),
          onSelected: (u) => _unit.text = u,
          itemBuilder: (_) => _units.map((u) => PopupMenuItem(value: u, child: Text(u))).toList(),
        ),
      ),
    );

    final qtyField = _stepperField(
      controller: _qty,
      label: AppTranslations.t('ui_pf_quantity'),
      validator: (v) => (int.tryParse((v ?? '').trim()) == null)
          ? AppTranslations.t('ui_please_enter_a_valid_quantity')
          : null,
    );

    final lowField = _stepperField(
      controller: _low,
      label: AppTranslations.t('ui_pf_alert_at'),
      helper: AppTranslations.t('ui_pf_alert_hint'),
    );

    Widget pair(Widget a, Widget b) => wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
          )
        : Column(children: [a, const SizedBox(height: 12), b]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppTranslations.t('ui_pf_basic')),
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v ?? '').trim().isEmpty
              ? AppTranslations.t('ui_please_enter_the_product_name')
              : null,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: _dec(AppTranslations.t('ui_product_name'), hint: AppTranslations.t('ui_pf_name_hint')),
        ),
        const SizedBox(height: 16),
        Text(AppTranslations.t('ui_category'),
            style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        _categoryChips(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _code,
          readOnly: _isEditing,
          decoration: _dec(
            AppTranslations.t('ui_product_code'),
            hint: _isEditing ? null : AppTranslations.t('ui_pf_code_auto'),
            prefix: const Icon(Icons.qr_code_2_rounded, color: _muted),
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle(AppTranslations.t('ui_pf_pricing')),
        pair(priceField, unitField),
        const SizedBox(height: 12),
        pair(qtyField, lowField),
      ],
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.92;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 880, maxHeight: maxH),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 640;
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _previewPanel(wide: true),
                            const SizedBox(width: 32),
                            Expanded(child: _formPanel(true)),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _previewPanel(wide: false),
                          const SizedBox(height: 24),
                          _formPanel(false),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? AppTranslations.t('ui_edit_product') : AppTranslations.t('ui_add_new_product'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primaryDarkBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isEditing ? AppTranslations.t('ui_pf_edit_subtitle') : AppTranslations.t('ui_pf_add_subtitle'),
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppTranslations.t('ui_close'),
            onPressed: _saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            color: _muted,
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      child: Row(
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _muted,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppTranslations.t('ui_cancel')),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(_isEditing ? Icons.check_rounded : Icons.add_rounded),
            label: Text(_isEditing ? AppTranslations.t('ui_save') : AppTranslations.t('ui_pf_create')),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.primaryDarkBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
