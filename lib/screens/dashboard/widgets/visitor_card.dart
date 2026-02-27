import 'package:flutter/material.dart';

import '../../../models/visitor_request.dart';

class VisitorCard extends StatelessWidget {
  const VisitorCard({
    super.key,
    required this.visitor,
    this.onApprove,
    this.onReject,
  });

  final VisitorRequest visitor;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  /// Show Approve/Reject only for security_based; host_based is handled in host app.
  bool get _showApproveReject =>
      visitor.approvalMode == ApprovalMode.security_based;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (visitor.visitorName != null && visitor.visitorName!.isNotEmpty)
                  Expanded(
                    child: Text(
                      visitor.visitorName!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                if (visitor.approvalMode != null) ...[
                  if (visitor.visitorName != null && visitor.visitorName!.isNotEmpty)
                    const SizedBox(width: 8),
                  _ApprovalModeChip(mode: visitor.approvalMode!),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visitor.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  visitor.contactNo,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (_showApproveReject) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApprovalModeChip extends StatelessWidget {
  const _ApprovalModeChip({required this.mode});

  final ApprovalMode mode;

  @override
  Widget build(BuildContext context) {
    final isSecurity = mode == ApprovalMode.security_based;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSecurity ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isSecurity ? 'Security' : 'Host',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSecurity ? Colors.blue.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
