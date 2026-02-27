import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/visitor_request.dart';

class HistoryListTile extends StatelessWidget {
  const HistoryListTile({
    super.key,
    required this.visitor,
  });

  final VisitorRequest visitor;

  @override
  Widget build(BuildContext context) {
    final time = visitor.updatedAt ?? visitor.createdAt;
    final isApproved = visitor.status == VisitorStatus.approved;
    final isRejected = visitor.status == VisitorStatus.rejected;

    final Color avatarBg;
    final Color avatarIcon;
    final IconData avatarIconData;

    if (isApproved) {
      avatarBg = Colors.green.shade100;
      avatarIcon = Colors.green.shade700;
      avatarIconData = Icons.check;
    } else if (isRejected) {
      avatarBg = Colors.red.shade100;
      avatarIcon = Colors.red.shade700;
      avatarIconData = Icons.close;
    } else {
      avatarBg = Colors.grey.shade200;
      avatarIcon = Colors.grey.shade600;
      avatarIconData = Icons.help_outline;
    }

    final String badgeText;
    if (isApproved) {
      badgeText = 'APPROVED';
    } else if (isRejected) {
      badgeText = 'REJECTED';
    } else {
      badgeText = visitor.status.name.toUpperCase();
    }

    final Color badgeBg = isApproved
        ? Colors.green.shade50
        : isRejected
            ? Colors.red.shade50
            : Colors.grey.shade100;
    final Color badgeTextColor = isApproved
        ? Colors.green.shade700
        : isRejected
            ? Colors.red.shade700
            : Colors.grey.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: avatarBg,
          child: Icon(
            avatarIconData,
            color: avatarIcon,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: badgeTextColor,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                visitor.visitorName ?? visitor.email,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (visitor.approvalMode != null) ...[
              const SizedBox(width: 8),
              _ApprovalModeChip(mode: visitor.approvalMode!),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            if (visitor.hostName != null && visitor.hostName!.isNotEmpty)
              _LabelRow(label: 'Host name', value: visitor.hostName!),
            if (visitor.hostCompanyName != null &&
                visitor.hostCompanyName!.isNotEmpty)
              _LabelRow(
                  label: 'Host company', value: visitor.hostCompanyName!),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(time),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            if (visitor.rejectRemark != null &&
                visitor.rejectRemark!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Remark: ${visitor.rejectRemark}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: isApproved
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                fontSize: 12,
              ),
            ),
            TextSpan(text: value, style: const TextStyle(fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSecurity ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isSecurity ? 'Security' : 'Host',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isSecurity ? Colors.blue.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
