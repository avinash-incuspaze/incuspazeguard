import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../models/visit_with_visitors.dart';
import '../../services/visitor_service.dart';

/// One row in the list: a visitor that can be checked out, with visit context.
class _VisitorRow {
  final VisitWithVisitors visit;
  final VisitorInVisit visitor;

  _VisitorRow(this.visit, this.visitor);
}

class VisitorsListScreen extends StatefulWidget {
  const VisitorsListScreen({super.key, this.showBackButton = true});

  /// When false, hides the back button (e.g. when shown inside main shell nav).
  final bool showBackButton;

  @override
  State<VisitorsListScreen> createState() => _VisitorsListScreenState();
}

class _VisitorsListScreenState extends State<VisitorsListScreen>
    with SingleTickerProviderStateMixin {
  final _visitorService = VisitorService();
  final List<_VisitorRow> _rowsCheckedIn = [];
  final List<_VisitorRow> _rowsCheckedOut = [];
  final List<_VisitorRow> _rowsPending = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  VisitorsPagination? _pagination;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  static const int _perPage = 10;
  late TabController _tabController;
  final ScrollController _scrollControllerCheckedIn = ScrollController();
  final ScrollController _scrollControllerCheckedOut = ScrollController();
  final ScrollController _scrollControllerPending = ScrollController();
  static const double _loadMoreScrollThreshold = 200;

  List<_VisitorRow> get _filteredCheckedIn => _filterRows(_rowsCheckedIn);
  List<_VisitorRow> get _filteredCheckedOut => _filterRows(_rowsCheckedOut);
  List<_VisitorRow> get _filteredPending => _filterRows(_rowsPending);

  List<_VisitorRow> _filterRows(List<_VisitorRow> rows) {
    if (_searchQuery.trim().isEmpty) return rows;
    final q = _searchQuery.trim().toLowerCase();
    return rows.where((row) {
      final v = row.visitor;
      final visit = row.visit;
      final checkInStr = _formatTime(v.checkInTime).toLowerCase();
      final checkOutStr = _formatTime(v.checkOutTime).toLowerCase();
      return v.fullName.toLowerCase().contains(q) ||
          (visit.hostName?.toLowerCase().contains(q) ?? false) ||
          (visit.companyName?.toLowerCase().contains(q) ?? false) ||
          visit.centerName.toLowerCase().contains(q) ||
          checkInStr.contains(q) ||
          checkOutStr.contains(q);
    }).toList();
  }

  static String _displayOptional(String? value) {
    if (value == null || value.isEmpty) return '—';
    if (value.length > 60 || value.startsWith('eyJ')) return '—';
    return value;
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPage(1);
    _scrollControllerCheckedIn.addListener(_onScrollCheckedIn);
    _scrollControllerCheckedOut.addListener(_onScrollCheckedOut);
    _scrollControllerPending.addListener(_onScrollPending);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollControllerCheckedIn.removeListener(_onScrollCheckedIn);
    _scrollControllerCheckedOut.removeListener(_onScrollCheckedOut);
    _scrollControllerPending.removeListener(_onScrollPending);
    _scrollControllerCheckedIn.dispose();
    _scrollControllerCheckedOut.dispose();
    _scrollControllerPending.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScrollPending() => _onScroll(_scrollControllerPending);

  void _onScrollCheckedIn() => _onScroll(_scrollControllerCheckedIn);
  void _onScrollCheckedOut() => _onScroll(_scrollControllerCheckedOut);

  void _onScroll(ScrollController controller) {
    if (!_hasMore || _loadingMore) return;
    final position = controller.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent - _loadMoreScrollThreshold) {
      _loadPage(_page + 1);
    }
  }

  Future<void> _loadPage(int page) async {
    if (page == 1) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }

    final result = await _visitorService.getVisitorsWithVisit(
      page: page,
      perPage: _perPage,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadingMore = false;
      if (result == null) return;
      _pagination = result.pagination;
      _page = page;
      if (page == 1) {
        _rowsCheckedIn.clear();
        _rowsCheckedOut.clear();
        _rowsPending.clear();
      }
      for (final visit in result.data) {
        for (final visitor in visit.visitors) {
          final row = _VisitorRow(visit, visitor);
          // Normalize status and detect check-in via timestamps when possible.
          final s = (visitor.status ?? '').toLowerCase();

          final hasCheckIn = visitor.checkInTime != null;
          final hasCheckOut = visitor.checkOutTime != null;

          // Pending tab: only show explicit pre-check-in requests
            // Include 'approved' and 'accepted' so pre-check-in approvals remain in Pending
            final pendingStatuses = {'pending', 'requested', 'accepted', 'approved'};
          if (pendingStatuses.contains(s)) {
            _rowsPending.add(row);
            continue;
          }

          if (s == 'checked_out' || hasCheckOut) {
            _rowsCheckedOut.add(row);
            continue;
          }

          // Check-in tab: only visitors that are checked-in (status or timestamp)
          if (s == 'checked_in' || hasCheckIn) {
            _rowsCheckedIn.add(row);
            continue;
          }

          // // Checked-out tab: only visitors that are checked-out (status or timestamp)
          // if (s == 'checked_out' || hasCheckOut) {
          //   _rowsCheckedOut.add(row);
          //   continue;
          // }

          // All other statuses (e.g., accepted/approved/unknown) are intentionally
          // not added to any tab to match the strict tab rules requested.
        }
      }

      debugPrint('VisitorsList: page=$page pending=${_rowsPending.length} checkedIn=${_rowsCheckedIn.length} checkedOut=${_rowsCheckedOut.length}');
    });
  }

  Future<void> _onCheckout(_VisitorRow row) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Check out visitor'),
        content: Text(
          'Check out ${row.visitor.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Check out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final success = await _visitorService.checkout(
      visitId: row.visit.visitId,
      visitorId: row.visitor.visitorId,
    );
    if (!mounted) return;
    if (success) {
      Get.snackbar('Done', '${row.visitor.fullName} checked out');
      _loadPage(1);
    } else {
      Get.snackbar('Error', 'Checkout failed. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Check-in'),
            Tab(text: 'Checked-out'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, host, company, centre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: () => _loadPage(1),
                        child: _buildTabList(
                          _filteredPending,
                          showCheckout: false,
                          scrollController: _scrollControllerPending,
                          isPending: true,
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: () => _loadPage(1),
                        child: _buildTabList(
                          _filteredCheckedIn,
                          showCheckout: true,
                          scrollController: _scrollControllerCheckedIn,
                        ),
                      ),
                      RefreshIndicator(
                        onRefresh: () => _loadPage(1),
                        child: _buildTabList(
                          _filteredCheckedOut,
                          showCheckout: false,
                          scrollController: _scrollControllerCheckedOut,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabList(
    List<_VisitorRow> rows, {
    required bool showCheckout,
    required ScrollController scrollController,
    bool isPending = false,
  }) {
    final isEmpty = rows.isEmpty;
    final isFiltered = _searchQuery.trim().isNotEmpty;
    if (isEmpty) {
      return _buildEmpty(
        showCheckout: showCheckout,
        isFiltered: isFiltered,
        isPending: isPending,
      );
    }
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rows.length +
          ((_hasMore || _loadingMore) && !isFiltered ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= rows.length) {
          return _buildLoadMore();
        }
        return _buildCard(rows[index], showCheckout: showCheckout);
      },
    );
  }

  bool get _hasMore =>
      _pagination != null &&
      _pagination!.hasMore &&
      !_loadingMore;

  Widget _buildEmpty({
    required bool showCheckout,
    bool isFiltered = false,
    bool isPending = false,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(
          isFiltered
              ? Icons.search_off
              : (showCheckout ? Icons.person_off_outlined : Icons.history),
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          isFiltered
              ? 'No matching visitors'
                  : (isPending
                    ? 'No pending requests'
                    : (showCheckout
                      ? 'No visitors in Check-in'
                      : 'No visitors in Checked-out')),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text(
          isFiltered
                ? 'Try a different search term.'
                : (isPending
                  ? 'Pending requests will appear here. Pull down to refresh.'
                  : (showCheckout
                    ? 'Visitors who are not yet checked out appear here. Pull down to refresh.'
                    : 'Checked-out visitors will appear here. Pull down to refresh.')),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        height: 56,
        child: Center(
          child: _loadingMore
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildCard(_VisitorRow row, {required bool showCheckout}) {
    final v = row.visitor;
    final visit = row.visit;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    v.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _statusLabel(v.status),
              ],
            ),
            const SizedBox(height: 8),
            _cardRow(Icons.login, 'Check-in: ${_formatTime(v.checkInTime)}',
                theme),
            const SizedBox(height: 2),
            _cardRow(Icons.logout, 'Check-out: ${_formatTime(v.checkOutTime)}',
                theme),
            const SizedBox(height: 4),
            _cardRow(Icons.person_outline, 'Host: ${_displayOptional(visit.hostName)}',
                theme),
            const SizedBox(height: 2),
            _cardRow(Icons.business_outlined, 'Company: ${_displayOptional(visit.companyName)}',
                theme),
            const SizedBox(height: 2),
            _cardRow(Icons.location_on_outlined, 'Centre: ${visit.centerName}',
                theme),
            if (showCheckout && row.visitor.canCheckout) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _onCheckout(row),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Check out'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _prettyStatus(String raw) {
    if (raw.isEmpty) return '—';
    final s = raw.replaceAll('_', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _statusLabel(String raw) {
    final s = raw.toLowerCase();
    Color bg;
    Color textColor;
    if (s == 'pending' || s == 'requested') {
      bg = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else if (s == 'accepted' || s == 'approved') {
      bg = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (s == 'checked_out') {
      bg = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    } else {
      bg = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _prettyStatus(raw),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _cardRow(IconData icon, String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
