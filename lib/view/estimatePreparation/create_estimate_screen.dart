
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';


class CreateEstimateScreen extends StatefulWidget {
  final bool showAppBar;
  final Map<String, dynamic>? existingEstimate; // ← add this
  final VoidCallback? onSubmitSuccess; // ← add this

  const CreateEstimateScreen({
    super.key,
    this.showAppBar = true,
    this.existingEstimate,
    this.onSubmitSuccess,  // ← add this

  });
  @override
  State<CreateEstimateScreen> createState() => _CreateEstimateScreenState();
}

class _CreateEstimateScreenState extends State<CreateEstimateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerSearchController = TextEditingController();
  final _contactController = TextEditingController();
  final _itemSearchController = TextEditingController();
  final _itemCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _rateController = TextEditingController();
  final _gstPercController = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedCustomerName;
  String? _selectedCustomerDisplay;
  bool _showCustomerDropdown = false;
  final _customerFocusNode = FocusNode();

  String? _selectedItemCode;
  bool _showItemDropdown = false;
  final _itemFocusNode = FocusNode();

  DateTime _date = DateTime.now();
  DateTime _validTill = DateTime.now().add(const Duration(days: 20));

  double _gstAmount = 0.0;
  double _totalAmount = 0.0;

  // Design tokens
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F0FF);
  static const _surface = Color(0xFFF8FAFB);
  static const _cardBg = Colors.white;
  static const _divider = Color(0xFFEEF1F4);
  static const _textMain = Color(0xFF1A1F2E);
  static const _textSub = Color(0xFF8A94A6);

  @override
  void initState() {
    super.initState();
    _rateController.addListener(_recalculate);
    _gstPercController.addListener(_recalculate);

    _customerFocusNode.addListener(() {
      if (!_customerFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150),
                () => setState(() => _showCustomerDropdown = false));
      }
    });
    _itemFocusNode.addListener(() {
      if (!_itemFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150),
                () => setState(() => _showItemDropdown = false));
      }
    });

    // ✅ Prefill if editing a draft
    if (widget.existingEstimate != null) {
      _prefillFromEstimate(widget.existingEstimate!);
    }
  }

  void _prefillFromEstimate(Map<String, dynamic> e) {
    // Customer
    _selectedCustomerName = e["customer"];
    _selectedCustomerDisplay = e["customer"];
    _customerSearchController.text = e["customer"] ?? '';

    // Contact
    _contactController.text = e["contact"] ?? '';

    // Valid Till
    if (e["valid_till"] != null) {
      try {
        _validTill = DateTime.parse(e["valid_till"]);
        // Description
        _itemDescController.text = e["item_description"] ?? '';

// Message — strip HTML tags from stored value
        final rawMessage = e["message"] ?? '';
        _messageController.text = rawMessage
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .trim();
      } catch (_) {}
    }

    // Item
    _selectedItemCode = e["item_code"];
    _itemSearchController.text = e["item_code"] ?? '';
    _itemCodeController.text = e["item_code"] ?? '';
    _itemNameController.text = e["item_name"] ?? '';

    // Pricing
    final rate = (e["rate"] ?? 0.0).toDouble();
    final gstPerc = double.tryParse(e["gst_perc"]?.toString() ?? '0') ?? 0.0;
    _rateController.text =
    rate % 1 == 0 ? rate.toInt().toString() : rate.toStringAsFixed(2);
    _gstPercController.text = gstPerc % 1 == 0
        ? gstPerc.toInt().toString()
        : gstPerc.toString();

    // Recalculate
    _gstAmount = (rate * gstPerc) / 100;
    _totalAmount = rate + _gstAmount;
  }
  void _recalculate() {
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final gstPerc = double.tryParse(_gstPercController.text) ?? 0.0;
    setState(() {
      _gstAmount = (rate * gstPerc) / 100;
      _totalAmount = rate + _gstAmount;
    });
  }

  Future<void> _onCustomerSearchChanged(String value) async {
    if (_selectedCustomerName != null) {
      setState(() {
        _selectedCustomerName = null;
        _selectedCustomerDisplay = null;
      });
    }
    if (value.trim().isEmpty) {
      setState(() => _showCustomerDropdown = false);
      return;
    }
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    await provider.searchCustomer(value.trim(), context);
    setState(() => _showCustomerDropdown = true);
  }

  Future<void> _selectCustomer(dynamic customer) async {
    setState(() {
      _selectedCustomerName = customer.name;
      _selectedCustomerDisplay = customer.customerName ?? customer.name;
      _customerSearchController.text = _selectedCustomerDisplay!;
      _showCustomerDropdown = false;
    });
    _customerFocusNode.unfocus();

    final estimateProvider = context.read<SalesOrderProvider>();
    final mobile = await estimateProvider.getCustomerContact(customer.name);
    if (mobile != null && mobile.isNotEmpty) {
      setState(() => _contactController.text = mobile);
    } else if ((customer.mobileNo ?? '').isNotEmpty) {
      setState(() => _contactController.text = customer.mobileNo!);
    }
  }

  Future<void> _onItemSearchChanged(String value) async {
    if (_selectedItemCode != null) {
      setState(() {
        _selectedItemCode = null;
        _itemCodeController.clear();
        _itemNameController.clear();
      });
    }
    if (value.trim().isEmpty) {
      setState(() => _showItemDropdown = false);
      return;
    }
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    await provider.itemSearchList(value.trim(), context, false);
    setState(() => _showItemDropdown = true);
  }

  Future<void> _selectItem(dynamic item) async {
    setState(() {
      _selectedItemCode = item.itemCode;
      _itemSearchController.text = item.itemCode ?? '';
      _itemCodeController.text = item.itemCode ?? '';
      _itemNameController.text = item.itemName ?? '';
      _showItemDropdown = false;
      _gstPercController.clear();
      _rateController.clear();
      _gstAmount = 0.0;
      _totalAmount = 0.0;
    });
    _itemFocusNode.unfocus();

    final estimateProvider = context.read<SalesOrderProvider>();
    final results = await Future.wait([
      estimateProvider.getItemGstPerc(item.itemCode ?? ''),
      estimateProvider.getItemRate(item.itemCode ?? ''),
    ]);

    final double? gstPerc = results[0];
    final double? rate = results[1];

    setState(() {
      if (gstPerc != null) {
        _gstPercController.text =
        gstPerc % 1 == 0 ? gstPerc.toInt().toString() : gstPerc.toString();
      }
      if (rate != null && rate > 0) {
        _rateController.text =
        rate % 1 == 0 ? rate.toInt().toString() : rate.toStringAsFixed(2);
      }
    });
    _recalculate();
  }

  Future<void> _pickDate(bool isValidTill) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isValidTill ? _validTill : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isValidTill ? _validTill = picked : _date = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerName == null) {
      _showSnack('Please select a customer from the list', Colors.orange);
      return;
    }

    final isEditing = widget.existingEstimate != null;
    final existingDocname = widget.existingEstimate?["name"] ?? '';

    // ── Step 1: Confirm before doing anything ─────────────────
    final confirmed = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_outlined, color: Color(0xFF1565C0), size: 20),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Update Estimate?' : 'Save Estimate?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Choose to save as draft or save and submit immediately.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A94A6))),
          ),
          // Save Draft only
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'draft'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color(0xFF1565C0)),
            ),
            child: const Text('Save Draft',
                style: TextStyle(color: Color(0xFF1565C0))),
          ),
          // Save + Submit
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'submit'),
            icon: const Icon(Icons.send_rounded, size: 14),
            label: const Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmed == null || confirmed == 'cancel') return;

    final provider = context.read<SalesOrderProvider>();

    // ── Step 2: Save draft (POST new / PUT existing) ──────────
    final saveResult = await provider.saveDraftEstimate(
      context: context,
      docname: isEditing ? existingDocname : null,
      customer: _selectedCustomerName!,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      contact: _contactController.text.trim(),
      validTill: DateFormat('yyyy-MM-dd').format(_validTill),
      itemCode: _itemCodeController.text.trim(),
      itemName: _itemNameController.text.trim(),
      itemDescription: _itemDescController.text.trim(),
      rate: double.tryParse(_rateController.text) ?? 0.0,
      gstPerc: double.tryParse(_gstPercController.text) ?? 0.0,
      message: _messageController.text.trim(),
    );

    if (!mounted) return;

    if (saveResult["success"] != true) {
      _showSnack(saveResult["error"] ?? 'Failed to save draft', Colors.red);
      return;
    }

    final savedDocname = saveResult["docname"] ?? '';

  //   // User chose Save Draft only
  //   if (confirmed == 'draft') {
  //     _showSnack('Draft saved: $savedDocname', Colors.blueGrey);
  //     Navigator.pop(context, true);
  //     return;
  //   }
  //
  //   // ── Step 3: Submit + WhatsApp ─────────────────────────────
  //   final submitResult = await provider.submitEstimate(
  //     context: context,
  //     docname: savedDocname,
  //     contact: _contactController.text.trim(),
  //   );
  //
  //   if (!mounted) return;
  //
  //   if (submitResult["success"] == true) {
  //     _showSnack(
  //       'Estimate $savedDocname submitted & WhatsApp sent!',
  //       Colors.green,
  //     );
  //     Navigator.pop(context, true);
  //   } else {
  //     _showSnack(
  //       submitResult["error"] ?? 'Submission failed',
  //       Colors.red,
  //     );
  //   }
  // }
    // User chose Save Draft only
    if (confirmed == 'draft') {
      _showSnack('Draft saved: $savedDocname', Colors.blueGrey);
      // ✅ Stay on screen — no navigation
      return;
    }

    // ── Step 3: Submit + WhatsApp ─────────────────────────────
    final submitResult = await provider.submitEstimate(
      context: context,
      docname: savedDocname,
      contact: _contactController.text.trim(),
    );

    if (!mounted) return;

    // if (submitResult["success"] == true) {
    //   _showSnack(
    //     'Estimate $savedDocname submitted & WhatsApp sent!',
    //     Colors.green,
    //   );
    //   // ✅ Navigate to list tab (index 1)
    //   Navigator.pop(context, true);
    // } else {
    //   _showSnack(
    //     submitResult["error"] ?? 'Submission failed',
    //     Colors.red,
    //   );
    // }
    if (submitResult["success"] == true) {
      _showSnack(
        'Estimate $savedDocname submitted & WhatsApp sent!',
        Colors.green,
      );

      if (widget.onSubmitSuccess != null) {
        // ✅ Called from tab — switch to list tab
        widget.onSubmitSuccess!();
      } else {
        // ✅ Called standalone (edit from list) — pop back
        Navigator.pop(context, true);
      }
    } else {
      _showSnack(
        submitResult["error"] ?? 'Submission failed',
        Colors.red,
      );
    }
  }
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _customerFocusNode.dispose();
    _contactController.dispose();
    _itemSearchController.dispose();
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _itemDescController.dispose();
    _rateController.dispose();
    _gstPercController.dispose();
    _messageController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      // appBar: AppBar(
      //   backgroundColor: AppColors.primaryColor,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   title: const Text(
      //     'New Estimate',
      //     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      //   ),
      //   bottom: PreferredSize(
      //     preferredSize: const Size.fromHeight(1),
      //     child: Container(color: Colors.white12, height: 1),
      //   ),
      // ),
      appBar: widget.showAppBar
          ? AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // title: const Text('New Estimate'),
        title: Text(
          widget.existingEstimate != null ? 'Edit Estimate' : 'New Estimate',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      )
          : null,
      body: Consumer<SalesOrderProvider>(
        builder: (context, estimateProvider, _) {
          return Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                  children: [
                    // ── Customer ──────────────────────────────────
                    _card(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF1565C0),
                      iconBg: const Color(0xFFE3F0FF),
                      title: 'Customer',
                      children: [
                        _buildCustomerSearchField(),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _contactController,
                          label: 'Contact',
                          hint: 'Phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

// ── Validity ──────────────────────────────────
                    _card(
                      icon: Icons.event_available_outlined,
                      iconColor: const Color(0xFF00897B),
                      iconBg: const Color(0xFFE0F2F1),
                      title: 'Validity',
                      children: [
                        GestureDetector(
                          onTap: () => _pickDate(true),
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 15, color: _textSub),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Valid Till',
                                        style: TextStyle(fontSize: 10, color: _textSub)),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(_validTill),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _textMain,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, size: 18, color: _textSub),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Item ──────────────────────────────────────
                    _card(
                      icon: Icons.inventory_2_outlined,
                      iconColor: const Color(0xFFE65100),
                      iconBg: const Color(0xFFFFF3E0),
                      title: 'Item',
                      children: [
                        // _buildItemSearchField(),
                        // const SizedBox(height: 12),
                        // // Read-only item name
                        // _readOnlyTile(
                        //   label: 'Item Name',
                        //   value: _itemNameController.text,
                        //   placeholder: 'Auto-filled on selection',
                        // ),
                        _buildItemSearchField(),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _itemDescController,
                          label: 'Description',
                          hint: 'Optional description',
                          icon: Icons.notes_rounded,
                          maxLines: 2,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Pricing ───────────────────────────────────
                    _card(
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFF6A1B9A),
                      iconBg: const Color(0xFFF3E5F5),
                      title: 'Pricing',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildField(
                                controller: _rateController,
                                label: 'Rate (₹)',
                                hint: '0.00',
                                icon: Icons.currency_rupee_rounded,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null)
                                    return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: _buildField(
                                controller: _gstPercController,
                                label: 'GST %',
                                hint: '0',
                                icon: Icons.percent_rounded,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null)
                                    return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _priceSummary(),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Message ───────────────────────────────────
                    _card(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: const Color(0xFF0277BD),
                      iconBg: const Color(0xFFE1F5FE),
                      title: 'Message',
                      children: [
                        _buildField(
                          controller: _messageController,
                          label: 'Note to customer',
                          hint: 'Please check the estimate',
                          icon: Icons.edit_note_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Sticky bottom bar ──────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _bottomBar(estimateProvider),
              ),

              if (estimateProvider.isCreatingEstimate)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: _primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Card wrapper ────────────────────────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textMain,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _divider),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Field ───────────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _textMain),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: _textSub.withOpacity(0.6), fontSize: 13),
        labelStyle: const TextStyle(fontSize: 13, color: _textSub),
        prefixIcon: Icon(icon, size: 18, color: _textSub),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        isDense: true,
      ),
    );
  }

  // ─── Date tile ───────────────────────────────────────────────────────────────

  Widget _dateTile({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 15, color: _textSub),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, color: _textSub)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(value),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textMain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Read-only tile ──────────────────────────────────────────────────────────

  Widget _readOnlyTile({
    required String label,
    required String value,
    required String placeholder,
  }) {
    final hasValue = value.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasValue ? _primaryLight.withOpacity(0.4) : _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasValue ? _primary.withOpacity(0.3) : _divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasValue ? Icons.check_circle_outline : Icons.auto_fix_high,
            size: 16,
            color: hasValue ? _primary : _textSub,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, color: _textSub)),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value : placeholder,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue ? _textMain : _textSub.withOpacity(0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Price summary ───────────────────────────────────────────────────────────

  Widget _priceSummary() {
    final rate =
        double.tryParse(_rateController.text) ?? 0.0;
    final gstLabel =
    _gstPercController.text.isEmpty ? '0' : _gstPercController.text;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF40E0D0), Color(0xFF40E0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _summaryRow('Rate', rate, small: true),
          const SizedBox(height: 6),
          _summaryRow('GST ($gstLabel%)', _gstAmount, small: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
                color: Colors.white.withOpacity(0.2), height: 1),
          ),
          _summaryRow('Total', _totalAmount, small: false),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {required bool small}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: small ? 12 : 14,
            color: small ? Colors.white70 : Colors.white,
            fontWeight: small ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
        Text(
          '₹ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: small ? 13 : 16,
            color: Colors.white,
            fontWeight: small ? FontWeight.w500 : FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ─── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _bottomBar(SalesOrderProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mini total preview
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total Amount',
                    style: TextStyle(fontSize: 11, color: _textSub)),
                Text(
                  '₹ ${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Submit button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: provider.isCreatingEstimate ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primary.withOpacity(0.5),
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // child: provider.isCreatingEstimate
              //     ? const SizedBox(
              //   height: 20,
              //   width: 20,
              //   child: CircularProgressIndicator(
              //     strokeWidth: 2.5,
              //     color: Colors.white,
              //   ),
              // )
              //     : const Row(
              //   children: [
              //     Icon(Icons.send_rounded, size: 16),
              //     SizedBox(width: 8),
              //     Text(
              //       'Submit',
              //       style: TextStyle(
              //         fontSize: 15,
              //         fontWeight: FontWeight.w700,
              //       ),
              //     ),
              //   ],
              // ),
              child: provider.isCreatingEstimate
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.send_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    widget.existingEstimate != null ? 'Update & Submit' : 'Submit',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Customer search ─────────────────────────────────────────────────────────

  Widget _buildCustomerSearchField() {
    return Consumer<SalesOrderProvider>(
      builder: (context, salesProvider, _) {
        final results = salesProvider.customerSearchModel?.data ?? [];
        return Column(
          children: [
            TextFormField(
              controller: _customerSearchController,
              focusNode: _customerFocusNode,
              onChanged: _onCustomerSearchChanged,
              validator: (_) => _selectedCustomerName == null
                  ? 'Please select a customer'
                  : null,
              style: const TextStyle(fontSize: 14, color: _textMain),
              decoration: InputDecoration(
                labelText: 'Customer',
                hintText: 'Search by name...',
                hintStyle:
                TextStyle(color: _textSub.withOpacity(0.6), fontSize: 13),
                labelStyle:
                const TextStyle(fontSize: 13, color: _textSub),
                prefixIcon: const Icon(Icons.person_search_outlined,
                    size: 18, color: _textSub),
                suffixIcon: salesProvider.isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child:
                    CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : _selectedCustomerName != null
                    ? IconButton(
                  icon: const Icon(Icons.cancel,
                      color: _textSub, size: 18),
                  onPressed: () => setState(() {
                    _selectedCustomerName = null;
                    _selectedCustomerDisplay = null;
                    _customerSearchController.clear();
                    _contactController.clear();
                    _showCustomerDropdown = false;
                  }),
                )
                    : const Icon(Icons.search, size: 18, color: _textSub),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                  const BorderSide(color: _primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                isDense: true,
              ),
            ),
            _buildDropdown(
              show: _showCustomerDropdown,
              isEmpty: results.isEmpty,
              isLoading: salesProvider.isLoading,
              emptyText: 'No customers found',
              itemCount: results.length,
              itemBuilder: (index) {
                final c = results[index];
                final name = c.customerName ?? c.name ?? '';
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 2),
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: _primaryLight,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primary),
                    ),
                  ),
                  title: Text(name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: (c.mobileNo ?? '').isNotEmpty
                      ? Text(c.mobileNo!,
                      style: const TextStyle(
                          fontSize: 11, color: _textSub))
                      : null,
                  onTap: () => _selectCustomer(c),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ─── Item search ─────────────────────────────────────────────────────────────
  Widget _buildItemSearchField() {
    return Consumer<SalesOrderProvider>(
      builder: (context, salesProvider, _) {
        final results = salesProvider.itemListModel?.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _itemSearchController,
              focusNode: _itemFocusNode,
              onChanged: _onItemSearchChanged,
              validator: (_) =>
              _selectedItemCode == null ? 'Please select an item' : null,
              style: const TextStyle(fontSize: 14, color: _textMain),
              decoration: InputDecoration(
                labelText: 'Item',
                hintText: 'Search item code or name...',
                hintStyle:
                TextStyle(color: _textSub.withOpacity(0.6), fontSize: 13),
                labelStyle: const TextStyle(fontSize: 13, color: _textSub),
                prefixIcon: const Icon(Icons.qr_code_outlined,
                    size: 18, color: _textSub),
                suffixIcon: salesProvider.isLoadingItem
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : _selectedItemCode != null
                    ? IconButton(
                  icon: const Icon(Icons.cancel,
                      color: _textSub, size: 18),
                  onPressed: () => setState(() {
                    _selectedItemCode = null;
                    _itemSearchController.clear();
                    _itemCodeController.clear();
                    _itemNameController.clear();
                    _gstPercController.clear();
                    _rateController.clear();
                    _gstAmount = 0.0;
                    _totalAmount = 0.0;
                    _showItemDropdown = false;
                  }),
                )
                    : const Icon(Icons.search, size: 18, color: _textSub),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                isDense: true,
              ),
            ),

            // ✅ Show item name inline below field after selection
            if (_itemNameController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 13, color: _primary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _itemNameController.text,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _primary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            _buildDropdown(
              show: _showItemDropdown,
              isEmpty: results.isEmpty,
              isLoading: salesProvider.isLoadingItem,
              emptyText: 'No items found',
              itemCount: results.length,
              itemBuilder: (index) {
                final item = results[index];
                return ListTile(
                  dense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        size: 15, color: Color(0xFFE65100)),
                  ),
                  title: Text(item.itemCode ?? '',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(item.itemName ?? '',
                      style: const TextStyle(fontSize: 11, color: _textSub)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (item.actualQty ?? 0) > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (item.actualQty ?? 0) > 0
                            ? Colors.green.shade300
                            : Colors.red.shade300,
                      ),
                    ),
                    child: Text(
                      'Qty: ${(item.actualQty ?? 0).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (item.actualQty ?? 0) > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  onTap: () => _selectItem(item),
                );
              },
              // itemBuilder: (index) {
              //   final item = results[index];
              //   return ListTile(
              //     dense: true,
              //     contentPadding:
              //     const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              //     leading: Container(
              //       width: 30,
              //       height: 30,
              //       decoration: BoxDecoration(
              //         color: const Color(0xFFFFF3E0),
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: const Icon(Icons.inventory_2_outlined,
              //           size: 15, color: Color(0xFFE65100)),
              //     ),
              //     title: Text(item.itemCode ?? '',
              //         style: const TextStyle(
              //             fontSize: 13, fontWeight: FontWeight.w600)),
              //     subtitle: Text(item.itemName ?? '',
              //         style: const TextStyle(fontSize: 11, color: _textSub)),
              //     onTap: () => _selectItem(item),
              //   );
              // },
            ),
          ],
        );
      },
    );
  }

  // ─── Shared dropdown shell ────────────────────────────────────────────────────

  Widget _buildDropdown({
    required bool show,
    required bool isEmpty,
    required bool isLoading,
    required String emptyText,
    required int itemCount,
    required Widget Function(int) itemBuilder,
  }) {
    if (!show) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: isEmpty && !isLoading
          ? Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.search_off, size: 15, color: _textSub),
            const SizedBox(width: 8),
            Text(emptyText,
                style:
                const TextStyle(fontSize: 13, color: _textSub)),
          ],
        ),
      )
          : ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
        const Divider(height: 1, color: _divider),
        itemBuilder: (_, i) => itemBuilder(i),
      ),
    );
  }
}