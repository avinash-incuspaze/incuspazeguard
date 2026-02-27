import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/visitor_request.dart';
import '../../services/visitor_service.dart';
import 'widgets/history_list_tile.dart';

/// Filter for approved history: all, security approved, or host approved.
enum ApprovedHistoryFilter { all, securityApproved, hostApproved }

class DateWiseHistoryScreen extends StatefulWidget {
  const DateWiseHistoryScreen({super.key});

  @override
  State<DateWiseHistoryScreen> createState() => _DateWiseHistoryScreenState();
}

class _DateWiseHistoryScreenState extends State<DateWiseHistoryScreen> {
  final _visitorService = VisitorService();
  final _searchController = TextEditingController();
  static const int _perPage = 10;
  /// null = show all dates; non-null = filter by this date.
  DateTime? _selectedDate;
  List<VisitorRequest> _all = [];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  ApprovedHistoryFilter _filter = ApprovedHistoryFilter.all;
  String _searchQuery = '';

  /// Safe read for hot reload when state may still hold old HistoryFilter.
  ApprovedHistoryFilter get _effectiveFilter {
    final name = _filter.name;
    if (name == 'securityApproved') return ApprovedHistoryFilter.securityApproved;
    if (name == 'hostApproved') return ApprovedHistoryFilter.hostApproved;
    return ApprovedHistoryFilter.all;
  }

  static bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads first page of approved drop-ins. Data is filtered in UI.
  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final result = await _visitorService.getApprovedPage(
      page: 1,
      perPage: _perPage,
    );
    if (mounted) {
      setState(() {
        _all = result.items;
        _page = 1;
        _hasMore = result.hasMore;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final result = await _visitorService.getApprovedPage(
      page: nextPage,
      perPage: _perPage,
    );
    if (mounted) {
      setState(() {
        _all = [..._all, ...result.items];
        _page = nextPage;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
  }

  List<VisitorRequest> get _filtered {
    var list = _all;
    if (_selectedDate != null) {
      list = list
          .where(
            (v) =>
                v.dateOfVisit != null &&
                _isSameDay(v.dateOfVisit, _selectedDate!),
          )
          .toList();
    }
    switch (_effectiveFilter) {
      case ApprovedHistoryFilter.securityApproved:
        list = list
            .where((v) => v.approvalMode == ApprovalMode.security_based)
            .toList();
        break;
      case ApprovedHistoryFilter.hostApproved:
        list = list
            .where((v) => v.approvalMode == ApprovalMode.host_based)
            .toList();
        break;
      case ApprovedHistoryFilter.all:
        break;
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((v) {
        final name = (v.visitorName ?? '').toLowerCase();
        final email = (v.email).toLowerCase();
        final contact = (v.contactNo).toLowerCase();
        final purpose = (v.purposeOfVisit ?? '').toLowerCase();
        final q = _searchQuery;
        return name.contains(q) ||
            email.contains(q) ||
            contact.contains(q) ||
            purpose.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date-wise history'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Select date'
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _clearDate,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear date'),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _effectiveFilter == ApprovedHistoryFilter.all,
                            onSelected: (_) {
                              setState(() => _filter = ApprovedHistoryFilter.all);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Security approved'),
                            selected: _effectiveFilter == ApprovedHistoryFilter.securityApproved,
                            onSelected: (_) {
                              setState(() => _filter = ApprovedHistoryFilter.securityApproved);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Host approved'),
                            selected: _effectiveFilter == ApprovedHistoryFilter.hostApproved,
                            onSelected: (_) {
                              setState(() => _filter = ApprovedHistoryFilter.hostApproved);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, purpose...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: _loading
                  ? _buildLoadingScroll()
                  : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Scrollable placeholder so RefreshIndicator works while loading.
  Widget _buildLoadingScroll() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      final byDate = _selectedDate != null;
      final bySearch = _searchQuery.isNotEmpty;
      String message;
      if (bySearch || byDate) {
        message = 'No matching approved visitors';
      } else {
        switch (_effectiveFilter) {
          case ApprovedHistoryFilter.securityApproved:
            message = 'No security-approved visitors';
            break;
          case ApprovedHistoryFilter.hostApproved:
            message = 'No host-approved visitors';
            break;
          case ApprovedHistoryFilter.all:
            message = 'No approved visitors yet';
        }
      }
      final emptyContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: emptyContent,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == list.length) {
          return _buildLoadMore();
        }
        return HistoryListTile(
          visitor: list[index],
        );
      },
    );
  }

  Widget _buildLoadMore() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: FilledButton.icon(
          onPressed: _hasMore ? _loadMore : null,
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text('Load more'),
        ),
      ),
    );
  }
}
