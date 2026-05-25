import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:sales_ordering_app/provider/provider.dart';
import 'package:sales_ordering_app/utils/app_colors.dart';
import 'package:sales_ordering_app/utils/common/common_widgets.dart';

import '../../utils/sharedpreference.dart';
import 'brochure_helper.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen>
    with SingleTickerProviderStateMixin {
  // String? _selectedBrand;
  String? _selectedCategory;
  SalesOrderProvider? _salesOrderProvider;

  // List<String> _brands = [];
  List<String> _categories = [];
  String? _selectedVariant;       // was _selectedBrand
  List<String> _variants = [];    // was _brands
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = false;
  String _cookies = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _scrollController.addListener(_onScroll);

    _fetchVariantList();
    _categoryList();
    _itemList();
    _loadCookies();

  }
  Future<void> _loadCookies() async {
    final pref = SharedPrefService();
    final cookies = await pref.getCookies();
    setState(() => _cookies = cookies ?? '');
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider =
      Provider.of<SalesOrderProvider>(context, listen: false);
      provider.loadMoreItems(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _salesOrderProvider =
        Provider.of<SalesOrderProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _salesOrderProvider?.clearCustomerList();
      _salesOrderProvider?.clearItemList();
    });
    super.dispose();
  }

  // ── Data fetchers (unchanged logic) ──────────────────────────────

  // Future<void> _fetchBrandList() async {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   try {
  //     Future.microtask(() async {
  //       final brandGroupList = await provider.brandList(context);
  //       setState(() {
  //         _brands =
  //             brandGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
  //       });
  //     });
  //   } catch (e) {
  //     debugPrint('Error fetching brands: $e');
  //   }
  // }
// 2. Replace _fetchBrandList with _fetchVariantList
  Future<void> _fetchVariantList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.fetchVariantList(context);
      setState(() {
        _variants = provider.variantList;
      });
    } catch (e) {
      debugPrint('Error fetching variants: $e');
    }
  }
  Future<void> _categoryList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      Future.microtask(() async {
        final categoryGroupList = await provider.categoryGroupList(context);
        setState(() {
          _categories =
              categoryGroupList?.data?.map((e) => e.name ?? '').toList() ?? [];
        });
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _itemList() async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      Future.microtask(() async => await provider.itemGroupList(context));
    } catch (e) {
      debugPrint('Error fetching items: $e');
    }
  }

  // Future<void> _itemBrandList(String brandname) async {
  //   final provider = Provider.of<SalesOrderProvider>(context, listen: false);
  //   try {
  //     Future.microtask(
  //             () async => await provider.itemByBrandList(brandname, context));
  //   } catch (e) {
  //     debugPrint('Error fetching item by brand: $e');
  //   }
  // }
  // 3. Replace _itemBrandList with _itemVariantList
  Future<void> _itemVariantList(String variantOf) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      Future.microtask(
              () async => await provider.itemByVariantList(variantOf, context));
    } catch (e) {
      debugPrint('Error fetching items by variant: $e');
    }
  }

  Future<void> _itemNameSearchList(String itemName) async {
    if (itemName.trim().isEmpty) return;
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      await provider.itemSearchListProducts(itemName.trim(), context);
    } catch (e) {
      debugPrint('Error fetching search: $e');
    }
  }

  Future<void> _categoryBrandList(String brand, String category) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      Future.microtask(() async =>
      await provider.categoryAndBrandList(brand, category, context));
    } catch (e) {
      debugPrint('Error fetching category+brand: $e');
    }
  }

  Future<void> _categoryFilterList(String category) async {
    final provider = Provider.of<SalesOrderProvider>(context, listen: false);
    try {
      Future.microtask(
              () async => await provider.itemByCategoryList(category, context));
    } catch (e) {
      debugPrint('Error fetching category items: $e');
    }
  }

  // ── Filter bottom sheet (replaces AlertDialog) ───────────────────

  void _showFilterSheet() {
    // Local copies so changes only apply on "Apply"
    String? tempVariant = _selectedVariant;
    String? tempCategory = _selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Items',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      // Clear all
                      if (tempVariant != null || tempCategory != null)
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempVariant = null;
                              tempCategory = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Clear all',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Variant dropdown (replaces Brand)
                  // _FilterDropdown(
                  //   label: 'Variant',
                  //   icon: Icons.device_hub_outlined,  // variant-appropriate icon
                  //   value: tempVariant,
                  //   items: _variants,
                  //   onChanged: (v) => setSheetState(() => tempVariant = v),
                  // ),
                  // const SizedBox(height: 16),

                  // Category dropdown
                  _FilterDropdown(
                    label: 'Category',
                    icon: Icons.category_outlined,
                    value: tempCategory,
                    items: _categories,
                    onChanged: (v) => setSheetState(() => tempCategory = v),
                  ),
                  const SizedBox(height: 28),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedVariant = tempVariant;
                          _selectedCategory = tempCategory;
                        });
                        Navigator.pop(ctx); // closes only the bottom sheet

                        if (tempVariant != null && tempCategory != null) {
                          // both: category filter takes priority; variant applied after
                          _categoryBrandList(tempVariant!, tempCategory!);
                        } else if (tempVariant != null) {
                          _itemVariantList(tempVariant!);
                        } else if (tempCategory != null) {
                          _categoryFilterList(tempCategory!);
                        } else {
                          _itemList();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters =
        _selectedVariant != null || _selectedCategory != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: CommonAppBar(
        title: 'Products',
        onBackTap: () => Navigator.pop(context),
        backgroundColor: AppColors.primaryColor,
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: Colors.white,
              ),
              tooltip: _isGridView ? 'List view' : 'Grid view',
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              tooltip: 'Search',
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: ItemSearchDelegate(
                    onItemSelected: _itemNameSearchList,
                  ),
                );
              },
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  tooltip: 'Filter',
                  onPressed: _showFilterSheet,
                ),
                if (hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: () {
                setState(() {
                  _selectedVariant = null;
                  _selectedCategory = null;
                });
                _itemList();
              },
            ),
          ],
        ),
      ),
      body: Consumer<SalesOrderProvider>(
        builder: (context, provider, child) {
          final String serverUrl = provider.serverUrl;

          if (provider.isLoading) {
            return const _LoadingView();
          }

          if (provider.errorMessage != null) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: _itemList,
            );
          }

          final items = provider.allItems;
          if (items.isEmpty) {
            return _EmptyView(onRefresh: _itemList);
          }

          return Column(
            children: [
              // ── Active filter chips bar ────────────────────────
              if (hasActiveFilters)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      if (_selectedVariant != null)
                        _ActiveChip(
                          label: _selectedVariant!,
                          onRemove: () {
                            setState(() => _selectedVariant = null);
                            if (_selectedCategory != null) {
                              _categoryFilterList(_selectedCategory!);
                            } else {
                              _itemList();
                            }
                          },
                        ),
                      if (_selectedVariant != null && _selectedCategory != null)
                        const SizedBox(width: 6),
                      if (_selectedCategory != null)
                        _ActiveChip(
                          label: _selectedCategory!,
                          onRemove: () {
                            setState(() => _selectedCategory = null);
                            if (_selectedVariant != null) {
                              _itemVariantList(_selectedVariant!);
                            } else {
                              _itemList();
                            }
                          },
                        ),
                    ],
                  ),
                ),

              // ── Summary bar ────────────────────────────────────
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${items.length} item${items.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!provider.hasMoreItems)
                      const Text(
                        ' · All loaded',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),

              // ── List ───────────────────────────────────────────
              // Expanded(
              //   child: FadeTransition(
              //     opacity: _fadeAnimation,
              //     child: ListView.builder(
              //       controller: _scrollController,
              //       padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              //       // +1 for the bottom loader row
              //       itemCount: items.length + 1,
              //       itemBuilder: (ctx, index) {
              //         // Last slot: spinner or "end" indicator
              //         if (index == items.length) {
              //           if (provider.isFetchingMore) {
              //             return const Padding(
              //               padding: EdgeInsets.symmetric(vertical: 20),
              //               child: Center(
              //                 child: SizedBox(
              //                   width: 24,
              //                   height: 24,
              //                   child: CircularProgressIndicator(
              //                     strokeWidth: 2.5,
              //                   ),
              //                 ),
              //               ),
              //             );
              //           }
              //           if (!provider.hasMoreItems && items.isNotEmpty) {
              //             return Padding(
              //               padding: const EdgeInsets.symmetric(vertical: 20),
              //               child: Center(
              //                 child: Text(
              //                   '— No more items —',
              //                   style: TextStyle(
              //                     fontSize: 12,
              //                     color: Colors.grey[400],
              //                   ),
              //                 ),
              //               ),
              //             );
              //           }
              //           return const SizedBox.shrink();
              //         }
              //
              //         final item = items[index];
              //         return _ItemCard(item: item, index: index);
              //       },
              //     ),
              //   ),
              // ),
              // 3. Replace the Expanded list section in the Consumer builder
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _isGridView
                      ? GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length + 1,
                    itemBuilder: (ctx, index) {
                      if (index == items.length) {
                        if (provider.isFetchingMore) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      // return _ItemGridCard(item: items[index], index: index);
                      return _ItemGridCard(item: items[index], index: index, serverUrl: serverUrl,cookies: _cookies,);

                    },
                  )
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length + 1,
                    itemBuilder: (ctx, index) {
                      if (index == items.length) {
                        if (provider.isFetchingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          );
                        }
                        if (!provider.hasMoreItems && items.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                '— No more items —',
                                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      // return _ItemCard(item: items[index], index: index);
                      return _ItemCard(item: items[index], index: index, serverUrl: serverUrl,cookies: _cookies,);

                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item Card
// ─────────────────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final dynamic item; // replace with your actual Item model type
  final int index;
  final String serverUrl;
  final String cookies;

  const _ItemCard({required this.item, required this.index,required this.serverUrl, required this.cookies,});
  String? get _imageUrl {
    if (item.image == null || item.image!.trim().isEmpty) return null;
    return '$serverUrl${item.image!.trim()}';
  }
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 40),
      curve: Curves.easeOut,
      builder: (ctx, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
// Replace the GestureDetector return with:
      child: Stack(
          children: [
          // existing GestureDetector → Container (full card)
          GestureDetector(
          onTap: () {},
      child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _imageUrl != null
                      ? Image.network(
                    _imageUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 46,
                        height: 46,
                        color: AppColors.primaryColor.withOpacity(0.08),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => _AvatarFallback(
                        label: item.itemName ?? '?'),
                  )
                      : _AvatarFallback(label: item.itemName ?? '?'),
                ),
                const SizedBox(width: 12),

                // ── Details ───────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      if (item.itemName != null)
                        Text(
                          item.itemName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                            height: 1.3,
                          ),
                        ),
                      const SizedBox(height: 4),

                      // Code + Brand row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (item.itemCode != null)
                            _InfoBadge(
                              icon: Icons.qr_code_2_rounded,
                              text: item.itemCode!,
                            ),
                          if (item.brand != null)
                            _InfoBadge(
                              icon: Icons.storefront_outlined,
                              text: item.brand!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Category
                      if (item.itemGroup != null)
                        _InfoBadge(
                          icon: Icons.category_outlined,
                          text: item.itemGroup!,
                        ),

                    ],
                  ),
                ),

                const SizedBox(width: 8),

              ],
            ),
          ),
        ),
      ),
            // Share button top-left
            if (item.productBrochure != null &&
                item.productBrochure!.trim().isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: _BrochureShareButton(
                  brochurePath: item.productBrochure!,
                  itemName: item.itemName ?? '',
                  serverUrl: serverUrl,
                  cookies: cookies,
                ),
              ),
    ]
      ));
  }
}
// Small fallback for the 46×46 list avatar
class _AvatarFallback extends StatelessWidget {
  final String label;
  const _AvatarFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isNotEmpty ? label[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}
// 4. Add the _ItemGridCard widget (paste after the existing _ItemCard class)

class _ItemGridCard extends StatelessWidget {
  final dynamic item;
  final int index;
  final String serverUrl; // add this
  final String cookies;


  const _ItemGridCard({required this.item, required this.index, required this.serverUrl, required this.cookies,});
  // helper
  String? get _imageUrl {
    if (item.image == null || item.image!.trim().isEmpty) return null;
    return '$serverUrl${item.image!.trim()}';
  }
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 30),
      curve: Curves.easeOut,
      builder: (ctx, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
// Replace the GestureDetector return with:
      child: Stack(
          children: [
          // existing GestureDetector → Container (full card)
          GestureDetector(
          onTap: () {},
      child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ──────────────────────────────
              Expanded(

          child: ClipRRect(
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(16)),
        child: _imageUrl != null
            ? Image.network(
          _imageUrl!,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.primaryColor.withOpacity(0.05),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) =>
              _PlaceholderImage(label: item.itemName ?? '?'),
        )
            : _PlaceholderImage(label: item.itemName ?? '?'),
      ),

              ),

              // ── Info area ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.itemName != null)
                      Text(
                        item.itemName!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (item.itemCode != null)
                      Text(
                        item.itemCode!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.itemGroup != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.itemGroup!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                      ],
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
            // Share button top-left
            if (item.productBrochure != null &&
                item.productBrochure!.trim().isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: _BrochureShareButton(
                  brochurePath: item.productBrochure!,
                  itemName: item.itemName ?? '',
                  serverUrl: serverUrl,
                  cookies: cookies,
                ),
              ),
    ]
      )
    );
  }
}

// 5. Placeholder shown when image is null or fails to load
class _PlaceholderImage extends StatelessWidget {
  final String label;
  const _PlaceholderImage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryColor.withOpacity(0.07),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              label.isNotEmpty ? label[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: items
          .map((s) => DropdownMenuItem(
        value: s,
        child: Text(s, style: const TextStyle(fontSize: 13)),
      ))
          .toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      isExpanded: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State views
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final color =
        Color.lerp(Colors.grey[200], Colors.grey[300], _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 13, width: 160, color: color,
                        margin: const EdgeInsets.only(bottom: 8)),
                    Container(height: 11, width: 100, color: color),
                  ],
                ),
              ),
              Container(
                  width: 50, height: 26, decoration: BoxDecoration(color: color,
                  borderRadius: BorderRadius.circular(20))),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No items found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555))),
            const SizedBox(height: 6),
            Text('Try adjusting your filters',
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search delegate (unchanged logic, minor UX polish)
// ─────────────────────────────────────────────────────────────────────────────
//
// class ItemSearchDelegate extends SearchDelegate<String> {
//   final Function(String) onItemSelected;
//
//   ItemSearchDelegate({required this.onItemSelected});
//
//   @override
//   String get searchFieldLabel => 'Search items…';
//
//   @override
//   ThemeData appBarTheme(BuildContext context) {
//     return Theme.of(context).copyWith(
//       appBarTheme: AppBarTheme(
//         backgroundColor: AppColors.primaryColor,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       inputDecorationTheme: const InputDecorationTheme(
//         hintStyle: TextStyle(color: Colors.white70),
//         border: InputBorder.none,
//       ),
//       textTheme: const TextTheme(
//         titleLarge: TextStyle(color: Colors.white, fontSize: 16),
//       ),
//     );
//   }
//
//   @override
//   List<Widget> buildActions(BuildContext context) => [
//     if (query.isNotEmpty)
//       IconButton(
//         icon: const Icon(Icons.close, color: Colors.white),
//         onPressed: () => query = '',
//       ),
//   ];
//
//   @override
//   Widget buildLeading(BuildContext context) => IconButton(
//     icon: const Icon(Icons.arrow_back, color: Colors.white),
//     onPressed: () => close(context, ''),
//   );
//
//   @override
//   Widget buildResults(BuildContext context) {
//     onItemSelected(query);
//     return const SizedBox.shrink();
//   }
//
//   @override
//   Widget buildSuggestions(BuildContext context) => const SizedBox.shrink();
// }
class ItemSearchDelegate extends SearchDelegate<String> {
  final Function(String) onItemSelected;

  ItemSearchDelegate({required this.onItemSelected});

  @override
  String get searchFieldLabel => 'Search items…';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) {
    // Close the search overlay first so the list screen
    // is in the tree when notifyListeners() fires
    WidgetsBinding.instance.addPostFrameCallback((_) {
      close(context, query);
      onItemSelected(query);
    });
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}
class _BrochureShareButton extends StatelessWidget {
  final String brochurePath;
  final String itemName;
  final String serverUrl;
  final String cookies;

  const _BrochureShareButton({
    required this.brochurePath,
    required this.itemName,
    required this.serverUrl,
    required this.cookies,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => BrochureHelper(
        serverUrl: serverUrl,
        cookies: cookies,
      ).shareBrochure(
        brochurePath: brochurePath,
        itemName: itemName,
        context: context,
      ),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(Icons.share_rounded, size: 15, color: Colors.blue),
      ),
    );
  }
}