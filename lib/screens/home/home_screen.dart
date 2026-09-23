import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/visitor_request.dart';
import '../../services/visitor_service.dart';
import '../dashboard/widgets/visitor_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _visitorService = VisitorService();
  static const int _perPage = 10;
  List<VisitorRequest> _pending = [];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incuspaze Guard Portal'),
      ),
      body: _loading
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
    );
  }
}
