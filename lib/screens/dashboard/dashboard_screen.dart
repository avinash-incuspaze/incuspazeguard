import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/guard_user.dart';
import '../../models/visitor_request.dart';
import '../../services/auth_service.dart';
import '../../services/visitor_service.dart';
import 'widgets/visitor_card.dart';
import '../history/date_wise_history_screen.dart';
import '../login/login_screen.dart';
import '../visitors_list/visitors_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _visitorService = VisitorService();
  final _authService = AuthService();
  static const int _perPage = 10;
  List<VisitorRequest> _pending = [];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  GuardUser? _user;

  @override
  void initState() {
    super.initState();
    _loadPending();
    _authService.getCurrentUser().then((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  Future<void> _loadPending() async {
    setState(() => _loading = true);
    final result = await _visitorService.getPendingPage(
      page: 1,
      perPage: _perPage,
    );
    if (mounted) {
      setState(() {
        _pending = result.items;
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
    final result = await _visitorService.getPendingPage(
      page: nextPage,
      perPage: _perPage,
    );
    if (mounted) {
      setState(() {
        _pending = [..._pending, ...result.items];
        _page = nextPage;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    }
  }

  Future<void> _onApprove(VisitorRequest visitor) async {
    final remark = await _showRemarkDialog(
      title: 'Approve visitor',
      actionLabel: 'Approve',
    );
    if (remark == null) return;
    await _visitorService.approve(visitor.id, remark);
    _loadPending();
    Get.snackbar('Approved', '${visitor.email} has been approved');
  }

  Future<void> _onReject(VisitorRequest visitor) async {
    final remark = await _showRemarkDialog(
      title: 'Reject visitor',
      actionLabel: 'Reject',
    );
    if (remark == null) return;
    await _visitorService.reject(visitor.id, remark);
    _loadPending();
    Get.snackbar('Rejected', '${visitor.email} has been rejected');
  }

  Future<String?> _showRemarkDialog({
    required String title,
    required String actionLabel,
  }) async {
    final controller = TextEditingController();
    String? errorText;
    return Get.dialog<String>(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Remark',
                hintText: 'Enter at least 10 characters',
                errorText: errorText,
              ),
              maxLines: 3,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final t = controller.text.trim();
                  if (t.length < 10) {
                    setState(
                      () => errorText = 'Remark must be at least 10 characters',
                    );
                    return;
                  }
                  Get.back(result: t);
                },
                child: Text(actionLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.logout();
      Get.offAll(() => const LoginScreen());
    }
  }

  Widget _buildUserDetails(GuardUser user) {
    final theme = Theme.of(context);
    String value(String? v) => (v != null && v.isNotEmpty) ? v : '—';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User details',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _detailRow(Icons.email_outlined, 'Email', value(user.email)),
            _detailRow(Icons.badge_outlined, 'Role', value(user.role)),
            _detailRow(Icons.business_outlined, 'Centre', value(user.centreName)),
            _detailRow(Icons.apartment_outlined, 'Building', value(user.building)),
            _detailRow(Icons.location_on_outlined, 'Address', value(user.address)),
          ],
        ),
      ),
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incuspaze Guard Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Get.to(() => const VisitorsListScreen()),
            tooltip: 'Visitors list (check out)',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const DateWiseHistoryScreen()),
            tooltip: 'Date-wise approved & rejected',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_user != null) _buildUserDetails(_user!),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPending,
                    child: _pending.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 48),
                              Icon(
                                Icons.person_search_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pending visitors',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Pull down to refresh',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: _pending.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _pending.length) {
                                return _buildLoadMore();
                              }
                              final v = _pending[index];
                              return VisitorCard(
                                visitor: v,
                                onApprove: () => _onApprove(v),
                                onReject: () => _onReject(v),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
