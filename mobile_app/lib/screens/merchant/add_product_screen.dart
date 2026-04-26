// lib/screens/merchant/add_product_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/providers/inventory_provider.dart';
import 'package:mobile_app/providers/selected_product_provider.dart';
import 'package:mobile_app/providers/shell_navigation_provider.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/theme/app_theme.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const AddProductScreen({super.key, required this.insideShell});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _threshCtrl= TextEditingController(text: '5');
  final _skuCtrl   = TextEditingController();
  final _catCtrl   = TextEditingController();
  final _descCtrl  = TextEditingController();

  File?   _imageFile;
  bool    _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _stockCtrl.dispose();
    _threshCtrl.dispose(); _skuCtrl.dispose(); _catCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      // 1. Create product
      final map = await apiService.createInventoryItem(
        name:      _nameCtrl.text.trim(),
        priceUsdc: double.parse(_priceCtrl.text.trim()),
        stock:     int.parse(_stockCtrl.text.trim()),
        threshold: int.tryParse(_threshCtrl.text.trim()) ?? 5,
        sku:       _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        category:  _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim(),
      );

      // 2. Upload image if selected
      if (_imageFile != null) {
        try {
          await apiService.uploadProductImage(map['id'] as String, _imageFile!);
        } catch (_) { /* non-fatal */ }
      }

      // 3. Refresh inventory
      await ref.read(inventoryProvider.notifier).refresh();

      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      setState(() { _error = apiService.parseError(e); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
                    _ImagePicker(file: _imageFile, onTap: _pickImage),
                    const SizedBox(height: 24),

                    // Fields
                    _Field(ctrl: _nameCtrl, label: 'Product name', hint: 'e.g. Wireless Mouse',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 12),
                    _Field(ctrl: _descCtrl, label: 'Description (optional)',
                      hint: 'Short product description', maxLines: 3),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _Field(
                        ctrl: _priceCtrl, label: 'Price (USDC)', hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) return 'Invalid';
                          return null;
                        },
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _Field(
                        ctrl: _stockCtrl, label: 'Initial stock', hint: '0',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Invalid';
                          return null;
                        },
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _Field(
                        ctrl: _threshCtrl, label: 'Low stock alert', hint: '5',
                        keyboardType: TextInputType.number,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _Field(ctrl: _skuCtrl, label: 'SKU (optional)', hint: 'SKU-001')),
                    ]),
                    const SizedBox(height: 12),
                    _Field(ctrl: _catCtrl, label: 'Category (optional)', hint: 'Electronics, Food...'),
                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DayFiColors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!, style: TextStyle(color: DayFiColors.red, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.onSurface,
                          foregroundColor: cs.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.surface))
                            : const Text('Save Product', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Edit Product Screen ────────────────────────────────────────────────────────

// lib/screens/merchant/edit_product_screen.dart
// (kept in same file for brevity — split if preferred)

class EditProductScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const EditProductScreen({super.key, required this.insideShell});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _stockCtrl  = TextEditingController();
  final _threshCtrl = TextEditingController();
  final _skuCtrl    = TextEditingController();
  final _catCtrl    = TextEditingController();
  final _descCtrl   = TextEditingController();

  File?   _imageFile;
  bool    _saving  = false;
  bool    _inited  = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final item = ref.read(selectedProductProvider);
    if (item == null) return;
    _nameCtrl.text   = item.name;
    _priceCtrl.text  = item.priceUsdc.toString();
    _stockCtrl.text  = item.stock.toString();
    _threshCtrl.text = item.threshold.toString();
    _skuCtrl.text    = item.sku ?? '';
    _catCtrl.text    = item.category ?? '';
    // description not in InventoryItem model yet — add if needed
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _stockCtrl.dispose();
    _threshCtrl.dispose(); _skuCtrl.dispose(); _catCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final item = ref.read(selectedProductProvider);
    if (item == null) return;

    setState(() { _saving = true; _error = null; });
    try {
      await apiService.updateInventoryItem(item.id, {
        'name':      _nameCtrl.text.trim(),
        'priceUsdc': double.parse(_priceCtrl.text.trim()),
        'stock':     int.parse(_stockCtrl.text.trim()),
        'threshold': int.tryParse(_threshCtrl.text.trim()) ?? 5,
        'sku':       _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        'category':  _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim(),
      });

      if (_imageFile != null) {
        try { await apiService.uploadProductImage(item.id, _imageFile!); } catch (_) {}
      }

      await ref.read(inventoryProvider.notifier).refresh();
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      setState(() { _error = apiService.parseError(e); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final item = ref.watch(selectedProductProvider);

    if (item == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('No product selected')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    _ImagePicker(
                      file: _imageFile,
                      existingUrl: item.imageUrl,
                      onTap: _pickImage,
                    ),
                    const SizedBox(height: 24),

                    _Field(ctrl: _nameCtrl, label: 'Product name', hint: 'e.g. Wireless Mouse',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _Field(
                        ctrl: _priceCtrl, label: 'Price (USDC)', hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) return 'Invalid';
                          return null;
                        },
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _Field(
                        ctrl: _stockCtrl, label: 'Stock', hint: '0',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Invalid';
                          return null;
                        },
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _Field(
                        ctrl: _threshCtrl, label: 'Low stock alert', hint: '5',
                        keyboardType: TextInputType.number,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _Field(ctrl: _skuCtrl, label: 'SKU', hint: 'SKU-001')),
                    ]),
                    const SizedBox(height: 12),
                    _Field(ctrl: _catCtrl, label: 'Category', hint: 'Electronics...'),
                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DayFiColors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!, style: TextStyle(color: DayFiColors.red, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.onSurface,
                          foregroundColor: cs.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.surface))
                            : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  final File?   file;
  final String? existingUrl;
  final VoidCallback onTap;
  const _ImagePicker({this.file, this.existingUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = file != null || existingUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.1)),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: file != null
                    ? Image.file(file!, fit: BoxFit.cover)
                    : Image.network(existingUrl!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 36,
                    color: cs.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Tap to add image',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4))),
                ],
              ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: cs.onSurface.withOpacity(0.55))),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.3)),
            filled: true,
            fillColor: cs.onSurface.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: DayFiColors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
