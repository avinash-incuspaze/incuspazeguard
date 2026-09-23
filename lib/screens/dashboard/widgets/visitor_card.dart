import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  /// Show Approve/Reject only when the approval status is pending.
  ///
  /// Buttons are visible for pending requests so the guard can approve
  /// or reject them; approved/rejected entries will not show the actions.
  bool get _showApproveReject {
    final pending = visitor.approvalStatus?.toLowerCase() == 'requested';
    final v = visitor.dateOfVisit;
    final now = DateTime.now();
    final visitDateOnly = v != null ? DateTime(v.year, v.month, v.day) : null;
    final todayOnly = DateTime(now.year, now.month, now.day);

    final visible = pending && (visitDateOnly == null ? true : visitDateOnly == todayOnly);
    debugPrint('VisitorCard: id=${visitor.id} approvalStatus=${visitor.approvalStatus} dateOfVisit=${visitor.dateOfVisit} CurrentDate=${todayOnly} showApprove=$visible');
    return visible;
  }

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
                const SizedBox(width: 8),
                _statusLabel(visitor.approvalStatus ?? visitor.status.name),
              ],
            ),
            const SizedBox(height: 6),
            if (visitor.visitId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Visit ID: ${visitor.visitId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
            // Show visit date & time when available
            if (visitor.dateOfVisit != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Visit: ${_formatVisitDateTime(visitor.dateOfVisit)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
            if (visitor.id.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Visitor ID: ${visitor.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),
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
            const SizedBox(height: 6),
            if (visitor.hostName != null && visitor.hostName!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Host: ${visitor.hostName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            if (visitor.hostCompanyName != null && visitor.hostCompanyName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.business_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Host company: ${visitor.hostCompanyName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
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

String _formatVisitDateTime(DateTime? dt) {
  if (dt == null) return '—';
  try {
    final local = dt.toLocal();
    return DateFormat('MMM d, yyyy • h:mm a').format(local);
  } catch (_) {
    return dt.toIso8601String();
  }
}
