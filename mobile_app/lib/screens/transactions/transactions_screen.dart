// lib/screens/transactions/transactions_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/widgets/app_bottomsheet.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// Helper functions
String _getAssetDisplayName(String asset) {
  switch (asset.toUpperCase()) {
    case 'USDC':
      return 'Digital Dollar';
    case 'XLM':
      return 'Stellar Lumen';
    default:
      return asset;
  }
}

String _getCurrencyLogoAsset(String asset) {
  switch (asset.toUpperCase()) {
    case 'USDC':
      return 'assets/images/usdc.png';
    case 'XLM':
      return 'assets/images/stellar.png';
    default:
      return 'assets/images/stellar.png';
  }
}

String _getStatusLabel(String? status) {
  switch (status?.toLowerCase()) {
    case 'confirmed':
      return 'Completed';
    case 'failed':
      return 'Failed';
    case 'in_progress':
    case 'pending':
      return 'In Progress';
    default:
      return 'Unknown';
  }
}

Color _getStatusColor(BuildContext context, String? status) {
  switch (status?.toLowerCase()) {
    case 'confirmed':
      return Theme.of(context).colorScheme.primary.withOpacity(.65);
    case 'failed':
      return DayFiColors.red;
    case 'in_progress':
    case 'pending':
      return const Color(0xFFFFA726); // Orange/Yellow
    default:
      return Theme.of(context).colorScheme.primary;
  }
}

String _getUsdAmount(double amount, String asset) {
  // USDC is 1:1 with USD
  if (asset.toUpperCase() == 'USDC') {
    return '\$${amount.toStringAsFixed(2)}';
  }
  // For XLM, use current rate (approximately 0.25 USD per XLM - update as needed)
  if (asset.toUpperCase() == 'XLM') {
    const xlmToUsd = 0.25; // Update with real-time rate from your backend
    final usdAmount = amount * xlmToUsd;
    return '\$${usdAmount.toStringAsFixed(2)}';
  }
  return '\$0.00';
}

class TransactionsScreen extends StatefulWidget {
  final TabController? tabController; // ← add this
  const TransactionsScreen({super.key, this.tabController});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TabController? _tabController;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  List<dynamic> _transactions = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  String _searchQuery = '';

  final _selectedAssets = <String>{};
  final _selectedTypes = <String>{};
  int _sortOption = 0;
  String? _assetFilter;
  String? _typeFilter;

  List<dynamic> _cachedFiltered = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.unfocus();
      widget.tabController?.addListener(_onTabChanged);
    });
  }

  void _onTabChanged() {
    // Transactions is tab index 1
    if ((widget.tabController?.index ?? 1) != 1) {
      _searchFocus.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void dispose() {
    widget.tabController?.removeListener(_onTabChanged);
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
        _refreshCache(); // ← add this, was missing
        if (mounted) setState(() {}); // trigger rebuild with new cache
      }
    });
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _transactions = [];
      });
    }

    try {
      final result = await apiService.getTransactions(page: _page, limit: 20);

      final txs = result['transactions'] as List;
      final pagination = result['pagination'];

      if (mounted) {
        setState(() {
          _transactions = refresh ? txs : [..._transactions, ...txs];
          _hasMore = _page < (pagination['pages'] ?? 1);
          _loading = false;
        });
        _refreshCache();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _refreshCache() {
    // Filter transactions
    _cachedFiltered = _transactions.where((tx) {
      final asset = (tx['asset'] as String?) ?? '';
      final type = (tx['type'] as String?) ?? '';
      final swapToAsset = (tx['swapToAsset'] as String?) ?? '';
      final swapFromAsset = (tx['swapFromAsset'] as String?) ?? '';

      // Hide the incoming swap leg (the duplicate)
      if (type == 'swap' && asset == swapToAsset && asset != swapFromAsset) {
        return false;
      }

      // Asset filter
      if (_selectedAssets.isNotEmpty && !_selectedAssets.contains(asset)) {
        return false;
      }

      // Type filter
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(type)) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final toUsername = (tx['toUsername'] as String?) ?? '';
        final displayName = _getAssetDisplayName(
          asset,
        ).toLowerCase(); // e.g. "stellar lumen", "digital dollar"
        final typedLabel = type == 'send'
            ? 'sent'
            : type == 'receive'
            ? 'received'
            : type == 'swap'
            ? 'swapped'
            : type;

        if (!toUsername.toLowerCase().contains(_searchQuery) &&
            !asset.toLowerCase().contains(
              _searchQuery,
            ) && // matches "xlm", "usdc"
            !displayName.contains(
              _searchQuery,
            ) && // matches "stellar lumen", "digital dollar"
            !typedLabel.contains(_searchQuery)) {
          // matches "sent", "received", "swapped"
          return false;
        }
      }

      return true;
    }).toList();

    // Sort
    _cachedFiltered.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      final amountA = (a['amount'] as num).toDouble();
      final amountB = (b['amount'] as num).toDouble();

      switch (_sortOption) {
        case 0: // Date newest first
          return dateB.compareTo(dateA);
        case 1: // Amount high to low
          return amountB.compareTo(amountA);
        case 2: // Amount low to high
          return amountA.compareTo(amountB);
        default:
          return dateB.compareTo(dateA);
      }
    });
  }

  void _applyFilter(String? type, String? asset) {
    setState(() {
      _typeFilter = type;
      _assetFilter = asset;
      if (type != null) {
        _selectedTypes.add(type);
      } else {
        _selectedTypes.clear();
      }
      if (asset != null) {
        _selectedAssets.add(asset);
      } else {
        _selectedAssets.clear();
      }
    });
    _refreshCache();
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
    List<dynamic> txs,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in txs) {
      final createdAt =
          DateTime.tryParse(tx['createdAt'] ?? '') ?? DateTime.now();
      final createdDate = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterdayDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );

      String dateLabel;
      if (createdDate == todayDate) {
        dateLabel = 'Today';
      } else if (createdDate == yesterdayDate) {
        dateLabel = 'Yesterday';
      } else {
        dateLabel = DateFormat('MMM d').format(createdAt);
      }

      grouped.putIfAbsent(dateLabel, () => []);
      grouped[dateLabel]!.add(tx as Map<String, dynamic>);
    }

    return grouped;
  }

  @override
  @override
  Widget build(BuildContext context) {
    final hasFilters = _assetFilter != null || _typeFilter != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main content list
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: () => _load(refresh: true),
                  child: _buildGroupedTransactionsList(),
                ),

          // Search bar overlay
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.02),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: hasFilters
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_assetFilter != null)
                                    _RemovableChip(
                                      label: _getAssetDisplayName(
                                        _assetFilter!,
                                      ),
                                      onRemove: () =>
                                          _applyFilter(_typeFilter, null),
                                    ),
                                  if (_typeFilter != null)
                                    _RemovableChip(
                                      label: _typeFilter! == 'send'
                                          ? 'Sent'
                                          : (_typeFilter == 'receive'
                                                ? 'Received'
                                                : (_typeFilter == 'swap'
                                                      ? 'Swapped'
                                                      : _typeFilter!)),
                                      onRemove: () =>
                                          _applyFilter(null, _assetFilter),
                                    ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 128,
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocus,
                                      textAlign: TextAlign.start,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 17.5,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: .4,
                                            height: 1.2,
                                          ),
                                      autofocus: false,
                                      cursorColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.5),
                                      decoration: InputDecoration(
                                        fillColor: Colors.transparent,
                                        hintText: 'Search',
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.5),
                                              fontSize: 17.5,
                                              fontWeight: FontWeight.w400,
                                              height: 1.2,
                                              letterSpacing: .4,
                                            ),
                                        prefixIcon: null,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 12,
                                            ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: SvgPicture.asset(
                                        'assets/icons/svgs/search.svg',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width -
                                          128,
                                      child: TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocus,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: 17.5,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: .4,
                                              height: 1.2,
                                            ),
                                        autofocus: false,
                                        cursorColor: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.5),
                                        decoration: InputDecoration(
                                          fillColor: Colors.transparent,
                                          hintText: 'Search',
                                          hintStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.5),
                                                fontSize: 17.5,
                                                fontWeight: FontWeight.w400,
                                                height: 1.2,
                                                letterSpacing: .4,
                                              ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 12,
                                              ),

                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterMenu(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SvgPicture.asset(
                          'assets/icons/svgs/filter.svg',
                          color: hasFilters
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.050),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
    // .animate().fadeIn(delay: 200.ms);
  }

  Widget _buildGroupedTransactionsList() {
    final grouped = _groupTransactionsByDate(_cachedFiltered);
    final dateLabels = grouped.keys.toList();

    dateLabels.sort((a, b) {
      if (a == 'Today') return -1;
      if (b == 'Today') return 1;
      if (a == 'Yesterday') return -1;
      if (b == 'Yesterday') return 1;
      return 0;
    });

    final items = <Map<String, dynamic>>[];
    int tileIndex = 0;

    for (final dateLabel in dateLabels) {
      items.add({'type': 'header', 'label': dateLabel});
      for (final tx in grouped[dateLabel]!) {
        items.add({'type': 'tile', 'tx': tx, 'index': tileIndex++});
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200 &&
            _hasMore &&
            !_loading) {
          setState(() => _page++);
          _load();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 140, 16, 100),
        itemCount: items.length + (_hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final item = items[i];

          if (item['type'] == 'header') {
            return Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                item['label'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          } else {
            return _TxTile(
              tx: item['tx'] as Map<String, dynamic>,
              index: item['index'] as int,
            );
          }
        },
      ),
    );
  }

  void _showFilterMenu() {
    showDayFiBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Filter',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('By Type'),
              trailing: _typeFilter != null
                  ? Text(
                      _typeFilter == 'send'
                          ? 'Sent'
                          : _typeFilter == 'receive'
                          ? 'Received'
                          : 'Swapped',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                _showTypeFilter();
              },
            ),
            ListTile(
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              leading: const Icon(Icons.toll_rounded),
              title: const Text('By Currency'),
              trailing: _assetFilter != null
                  ? Text(
                      _getAssetDisplayName(_assetFilter!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                _showAssetFilter();
              },
            ),
            if (_typeFilter != null || _assetFilter != null) ...[
              const SizedBox(height: 8),
              ListTile(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                leading: const Icon(
                  Icons.clear_rounded,
                  color: DayFiColors.red,
                ),
                title: const Text(
                  'Clear all filters',
                  style: TextStyle(color: DayFiColors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _applyFilter(null, null);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showTypeFilter() {
    showDayFiBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Filter by Type',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            _filterOption('All', null, isType: true),
            _filterOption('Sent', 'send', isType: true),
            _filterOption('Received', 'receive', isType: true),
            _filterOption('Swapped', 'swap', isType: true),
          ],
        ),
      ),
    );
  }

  void _showAssetFilter() {
    showDayFiBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Filter by Currency',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),
            _filterOption('All', null, isType: false),
            _filterOptionWithSubtitle(
              label: 'Digital Dollar',
              subtitle: 'USDC',
              value: 'USDC',
            ),
            _filterOptionWithSubtitle(
              label: 'Stellar Lumen',
              subtitle: 'XLM',
              value: 'XLM',
            ),
          ],
        ),
      ),
    );
  }

  // Add this new helper alongside _filterOption:
  Widget _filterOptionWithSubtitle({
    required String label,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _assetFilter == value;

    return ListTile(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          fontSize: 12,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        _applyFilter(_typeFilter, value);
      },
    );
  }

  Widget _filterOption(String label, String? value, {required bool isType}) {
    final current = isType ? _typeFilter : _assetFilter;
    final isSelected = current == value;

    return ListTile(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        if (isType) {
          _applyFilter(value, _assetFilter);
        } else {
          _applyFilter(_typeFilter, value);
        }
      },
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      // decoration: BoxDecoration(
      //   // color: Theme.of(context).colorScheme.primary.withOpacity(.15),
      //   // borderRadius: BorderRadius.circular(20),
      // ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

void _showTxDetails(BuildContext context, Map<String, dynamic> tx) {
  final isSend = tx['type'] == 'send';
  final isSwap = tx['type'] == 'swap';
  final amount = (tx['amount'] as num).toDouble();
  final asset = tx['asset'] as String;
  final assetDisplayName = _getAssetDisplayName(asset);
  final swapToAsset = (tx['swapToAsset'] as String?) ?? '';
  // final swapToAssetDisplayName = _getAssetDisplayName(swapToAsset);
  final swapToAmount = (tx['receivedAmount'] ?? tx['swapToAmount']) != null
      ? ((tx['receivedAmount'] ?? tx['swapToAmount']) as num).toDouble()
      : null;
  final createdAt = DateTime.tryParse(tx['createdAt'] ?? '') ?? DateTime.now();
  final txHash = tx['stellarTxHash'] as String?;
  final memo = tx['memo'] as String?;
  final fee = tx['fee'] as String?;
  final status = tx['status'] as String?;
  final toUsername = tx['toUsername'] as String?;

  showDayFiBottomSheet(
    context: context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Opacity(opacity: 0, child: Icon(Icons.close)),
              Text(
                'Details',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontSize: 16,
                  letterSpacing: -.1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Icon with stacked currency logo
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: Center(
                  child: SvgPicture.asset(
                    isSwap
                        ? 'assets/icons/svgs/swap.svg'
                        : (isSend
                              ? 'assets/icons/svgs/send.svg'
                              : 'assets/icons/svgs/receive.svg'),
                    color: _getStatusColor(context, status),
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      _getCurrencyLogoAsset(asset),
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Transaction type and asset name
          Text(
            isSwap
                ? 'Swapped $asset → $swapToAsset'
                : '${isSend ? 'Sent ' : 'Received '}$assetDisplayName',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 8),

          // Amount and status
          Text(
            isSwap
                ? '$amount $asset → ${swapToAmount != null ? '${swapToAmount.toStringAsFixed(2)} ' : ''}$swapToAsset'
                : '${amount.toStringAsFixed(2)} $asset',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: isSwap
                  ? Theme.of(context).colorScheme.primary
                  : (isSend ? DayFiColors.red : DayFiColors.green),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // USD Amount
          Text(
            _getUsdAmount(amount, asset),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary.withOpacity(1),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          // Status badge
          Text(
            _getStatusLabel(status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getStatusColor(context, status),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // Details rows
          _DetailRow(
            label: 'Type',
            value: isSwap ? 'Swapped' : (isSend ? 'Sent' : 'Received'),
          ),
          if (toUsername != null)
            _DetailRow(label: isSend ? 'To' : 'From', value: '@$toUsername'),
          _DetailRow(
            label: 'Date',
            value: DateFormat(
              'MMM d, yyyy · h:mm a',
            ).format(createdAt.toLocal()),
          ),
          if (memo != null && memo.isNotEmpty)
            _DetailRow(label: 'Memo', value: memo),
          if (fee != null) _DetailRow(label: 'Network fee', value: fee),
          if (txHash != null)
            _DetailRow(
              label: 'Tx Hash',
              value:
                  '${txHash.substring(0, 8)}...${txHash.substring(txHash.length - 8)}',
              mono: true,
            ),

          const SizedBox(height: 20),

          // View on Stellar Expert button
          if (txHash != null)
            SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(MediaQuery.of(context).size.width, 48),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.90),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    launchUrl(
                      Uri.parse(
                        'https://stellar.expert/explorer/public/tx/$txHash',
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.90),
                  ),
                  label: Text(
                    'View on Stellar Expert',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.90),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: mono ? 'monospace' : null,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final int index;

  const _TxTile({required this.tx, required this.index});

  @override
  Widget build(BuildContext context) {
    final isSend = tx['type'] == 'send';
    final isSwap = tx['type'] == 'swap';
    final amount = (tx['amount'] as num).toDouble();
    final asset = tx['asset'] as String;
    final assetDisplayName = _getAssetDisplayName(asset);
    final swapToAsset = (tx['swapToAsset'] as String?) ?? '';
    // final swapToAssetDisplayName = _getAssetDisplayName(swapToAsset);
    final swapToAmount = (tx['receivedAmount'] ?? tx['swapToAmount']) != null
        ? ((tx['receivedAmount'] ?? tx['swapToAmount']) as num).toDouble()
        : null;
    final createdAt =
        DateTime.tryParse(tx['createdAt'] ?? '') ?? DateTime.now();
    // final toUsername = tx['toUsername'] as String?;
    final status = tx['status'] as String?;

    return GestureDetector(
      onTap: () => _showTxDetails(context, tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Icon with stacked currency logo
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  // width: 40,
                  height: 40,
                  // decoration: BoxDecoration(
                  //   color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  //   borderRadius: BorderRadius.circular(12),
                  // ),
                  child: Center(
                    child: SvgPicture.asset(
                      isSwap
                          ? 'assets/icons/svgs/swap.svg'
                          : (isSend
                                ? 'assets/icons/svgs/send.svg'
                                : 'assets/icons/svgs/receive.svg'),
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(.75),
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        _getCurrencyLogoAsset(asset),
                        width: 14,
                        height: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction type and asset name
                  Text(
                    isSwap
                        ? 'Swapped $asset → $swapToAsset'
                        : '${isSend ? 'Sent ' : 'Received '}$assetDisplayName',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.95),
                      letterSpacing: -.1,
                    ),
                  ),

                  Text(
                    status?.toLowerCase() == "confirmed"
                        ? DateFormat('h:mm a').format(createdAt.toLocal())
                        : _getStatusLabel(status),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _getStatusColor(context, status),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // USD Amount
                Text(
                  _getUsdAmount(amount, asset),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary.withOpacity(1),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                // Coin Amount
                Text(
                  isSwap
                      ? '$amount $asset → ${swapToAmount != null ? '${swapToAmount.toStringAsFixed(2)} ' : ''}$swapToAsset'
                      : '${amount.toStringAsFixed(2)} $asset',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.65),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            // Time
          ],
        ),
      ),
      // .animate().fadeIn(delay: Duration(milliseconds: index * 50)),
    );
  }
}
