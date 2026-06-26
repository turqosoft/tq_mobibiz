import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import '../../provider/provider.dart';
import 'create_estimate_screen.dart';

class EstimateTabScreen extends StatefulWidget {
  const EstimateTabScreen({super.key});

  @override
  State<EstimateTabScreen> createState() => _EstimateTabScreenState();
}

class _EstimateTabScreenState extends State<EstimateTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // ✅ Key to force rebuild of CreateEstimateScreen
  Key _createScreenKey = UniqueKey();

  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  static const _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTabIndex = _tabController.index);
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        context.read<SalesOrderProvider>().fetchEstimateList(
          fromDate: _fromDate,
          toDate: _toDate,
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesOrderProvider>().fetchEstimateList(
        fromDate: _fromDate,
        toDate: _toDate,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _resetCreateScreen() {
    setState(() => _createScreenKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Estimates',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        // ✅ Plus icon — only visible on Create tab
        actions: [
          if (_currentTabIndex == 0)
            IconButton(
              tooltip: 'New Estimate',
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: _resetCreateScreen,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400, fontSize: 13),
          tabs: const [
            Tab(
                icon: Icon(Icons.add_circle_outline, size: 18),
                text: 'Create'),
            Tab(
                icon: Icon(Icons.list_alt_outlined, size: 18),
                text: 'My Estimates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ✅ UniqueKey forces full rebuild when plus is tapped
          CreateEstimateScreen(
            key: _createScreenKey,
            showAppBar: false,
            onSubmitSuccess: () {
              _tabController.animateTo(1);
              context.read<SalesOrderProvider>().fetchEstimateList(
                fromDate: _fromDate,
                toDate: _toDate,
              );
            },
          ),
          _EstimateListTab(
            onCreateTap: () => _tabController.animateTo(0),
            fromDate: _fromDate,
            toDate: _toDate,
            onFromDateChanged: (date) {
              setState(() => _fromDate = date);
              context.read<SalesOrderProvider>().fetchEstimateList(
                fromDate: date,
                toDate: _toDate,
              );
            },
            onToDateChanged: (date) {
              setState(() => _toDate = date);
              context.read<SalesOrderProvider>().fetchEstimateList(
                fromDate: _fromDate,
                toDate: date,
              );
            },
          ),
        ],
      ),
    );
  }
}
class _EstimateListTab extends StatelessWidget {
  final VoidCallback onCreateTap;
  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<DateTime> onFromDateChanged;
  final ValueChanged<DateTime> onToDateChanged;

  static const _primary = Color(0xFF1565C0);
  static const _textMain = Color(0xFF1A1F2E);
  static const _textSub = Color(0xFF8A94A6);
  static const _divider = Color(0xFFEEF1F4);

  const _EstimateListTab({
    required this.onCreateTap,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateChanged,
    required this.onToDateChanged,
  });

  Future<void> _pickDate(
      BuildContext context,
      DateTime initial,
      ValueChanged<DateTime> onPicked,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesOrderProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // ── Date Filter Bar ──────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // From date
                  Expanded(
                    child: _DateFilterTile(
                      label: 'From',
                      date: fromDate,
                      onTap: () =>
                          _pickDate(context, fromDate, onFromDateChanged),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: _textSub),
                  const SizedBox(width: 10),
                  // To date
                  Expanded(
                    child: _DateFilterTile(
                      label: 'To',
                      date: toDate,
                      onTap: () =>
                          _pickDate(context, toDate, onToDateChanged),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Refresh button
                  GestureDetector(
                    onTap: () {
                      final today = DateTime.now();
                      onFromDateChanged(today);
                      onToDateChanged(today);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F0FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          size: 18, color: _primary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _divider),

            // ── List ─────────────────────────────────────────
            Expanded(
              child: provider.isLoadingEstimates
                  ? const Center(
                  child: CircularProgressIndicator(color: _primary))
                  : provider.estimateList.isEmpty
                  ? _emptyState(context)
                  : RefreshIndicator(
                color: _primary,
                onRefresh: () => provider.fetchEstimateList(
                  fromDate: fromDate,
                  toDate: toDate,
                ),
                child: ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: provider.estimateList.length,
                  itemBuilder: (context, index) {
                    final estimate = provider.estimateList[index];
                    return _EstimateCard(
                      estimate: estimate,
                      fromDate: fromDate,   // ← pass
                      toDate: toDate,       // ← pass
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 40, color: _primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No estimates found',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _textMain),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different date range',
            style: TextStyle(fontSize: 13, color: _textSub),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Estimate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Filter Tile ─────────────────────────────────────────────────────────

class _DateFilterTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  static const _primary = Color(0xFF1565C0);
  static const _textMain = Color(0xFF1A1F2E);
  static const _textSub = Color(0xFF8A94A6);

  const _DateFilterTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEF1F4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: _primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                    const TextStyle(fontSize: 10, color: _textSub)),
                const SizedBox(height: 1),
                Text(
                  DateFormat('dd MMM yy').format(date),
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
}
// ─── Estimate Card ────────────────────────────────────────────────────────────

class _EstimateCard extends StatelessWidget {
  final Map<String, dynamic> estimate;
  final DateTime fromDate;    // ← add
  final DateTime toDate;
  static const _primary = Color(0xFF1565C0);
  static const _textMain = Color(0xFF1A1F2E);
  static const _textSub = Color(0xFF8A94A6);
  static const _divider = Color(0xFFEEF1F4);

  const _EstimateCard({
    required this.estimate,
    required this.fromDate,   // ← add
    required this.toDate,     // ← add
  });

  @override
  Widget build(BuildContext context) {
    final docstatus = estimate["docstatus"] ?? 0;
    final isDraft = docstatus == 0;

    final statusLabel = isDraft ? 'Draft' : 'Submitted';
    final statusColor = isDraft ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    final statusBg = isDraft ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9);

    final totalAmount = (estimate["total_amount"] ?? 0.0).toDouble();
    final gstPerc = estimate["gst_perc"]?.toString() ?? '0';
    final validTill = estimate["valid_till"] != null
        ? _formatDate(estimate["valid_till"])
        : '—';
    return GestureDetector(
      onTap: isDraft
          ? () async {
        final refreshed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => CreateEstimateScreen(
              showAppBar: true,
              existingEstimate: estimate, // ← pass estimate data
            ),
          ),
        );
        // Refresh list if submitted successfully
        if (refreshed == true && context.mounted) {
          context.read<SalesOrderProvider>().fetchEstimateList(
            fromDate: fromDate,
            toDate: toDate,
          );
        }
      }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
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
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estimate["name"] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          estimate["customer"] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  // ✅ Edit icon for drafts
                  if (isDraft) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined,
                        size: 16, color: _textSub),
                  ],
                ],
              ),
            ),

            Divider(height: 1, color: _divider),

// ── Details grid ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Code
                  _detailRow(
                    icon: Icons.qr_code_outlined,
                    label: 'Item Code',
                    value: estimate["item_code"] ?? '—',
                  ),
                  const SizedBox(height: 6),
                  // Item Name — full text, no trim
                  _detailRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Item Name',
                    value: estimate["item_name"] ?? '—',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 6),
                  // Contact
                  _detailRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    value: estimate["contact"] ?? '—',
                  ),
                  const SizedBox(height: 6),
                  // Valid Till + GST in one row
                  Row(
                    children: [
                      Expanded(
                        child: _detailRow(
                          icon: Icons.event_available_outlined,
                          label: 'Valid Till',
                          value: validTill,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _detailRow(
                          icon: Icons.percent_rounded,
                          label: 'GST',
                          value: '$gstPerc%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
// Rate + GST Amount in one row
                  Row(
                    children: [
                      Expanded(
                        child: _detailRow(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Rate',
                          // value: '₹ ${double.tryParse(estimate["rate"]?.toString() ?? '0') ?? 0.0}',
                          value: estimate["rate"].toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _detailRow(
                          icon: Icons.calculate_outlined,
                          label: 'GST Amt',
                          // value: '₹ ${double.tryParse(estimate["gst_amount"]?.toString() ?? '0') ?? 0.0}',
                          value: estimate["gst_amount"].toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Footer (unchanged) ────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F6FF),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount',
                      style: TextStyle(
                          fontSize: 12,
                          color: _textSub,
                          fontWeight: FontWeight.w500)),
                  Text(
                    // '₹ ${(estimate["total_amount"] ?? 0.0).toDouble().toStringAsFixed(2)}',
                    '₹ ${double.tryParse(estimate["total_amount"]?.toString() ?? '0') ?? 0.0}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: _textSub),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: _textSub),
          ),
        ),
        const Text(': ',
            style: TextStyle(fontSize: 11, color: _textSub)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textMain,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ),
      ],
    );
  }
  String _formatDate(String date) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}