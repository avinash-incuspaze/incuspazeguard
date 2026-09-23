enum VisitorStatus { pending, approved, rejected }

/// Who can approve: security (guard) or host (host app).
enum ApprovalMode { security_based, host_based }

class VisitorRequest {
  final String id;
  final String email;
  final String contactNo;
  final VisitorStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? rejectRemark;
  final String? visitorName;
  /// From API `approval_mode`: security_based = guard can approve/reject; host_based = host app only.
  final ApprovalMode? approvalMode;
  /// Raw approval status from backend (e.g. `pending`, `approved`, `rejected`).
  final String? approvalStatus;
  /// Visit ID when available (from `visit_id` in some backend payloads).
  final int? visitId;
  /// Visit date from API `date_of_visit` (for history date filter).
  final DateTime? dateOfVisit;
  /// Purpose from API `purpose_of_visit` (for search).
  final String? purposeOfVisit;
  /// Host name from API `host_name`.
  final String? hostName;
  /// Host company from API `host_company_name`.
  final String? hostCompanyName;
  /// Visitor's company from API `company.company_name` (same as contactNo when from drop-in).
  final String? visitorCompanyName;

  VisitorRequest({
    required this.id,
    required this.email,
    required this.contactNo,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.rejectRemark,
    this.visitorName,
    this.approvalMode,
    this.visitId,
    this.approvalStatus,
    this.dateOfVisit,
    this.purposeOfVisit,
    this.hostName,
    this.hostCompanyName,
    this.visitorCompanyName,
  });

  factory VisitorRequest.fromJson(Map<String, dynamic> json) {
    VisitorStatus status = VisitorStatus.pending;
    final s = json['status'] as String?;
    if (s == 'approved') status = VisitorStatus.approved;
    if (s == 'rejected') status = VisitorStatus.rejected;

    ApprovalMode? approvalMode;
    final visitId = (json['visit_id'] as num?)?.toInt();
    final mode = json['approval_mode']?.toString();
    if (mode == 'security_based') approvalMode = ApprovalMode.security_based;
    if (mode == 'host_based') approvalMode = ApprovalMode.host_based;

    return VisitorRequest(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      contactNo: json['contact_no'] as String? ?? json['contactNo'] as String? ?? '',
      status: status,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      rejectRemark: json['reject_remark'] as String? ?? json['rejectRemark'] as String?,
      visitorName: json['visitor_name'] as String? ?? json['visitorName'] as String?,
      approvalMode: approvalMode,
      visitId: visitId,
    );
  }

  /// Map a backend "drop-in" response item into our local model.
  /// This specifically understands the `/api/reception/drop-ins/manual` payload.
  factory VisitorRequest.fromDropInBackend(Map<String, dynamic> json) {
    VisitorStatus status = VisitorStatus.pending;
    final approval = json['approval_status']?.toString();
    if (approval == 'approved') {
      status = VisitorStatus.approved;
    } else if (approval == 'rejected') {
      status = VisitorStatus.rejected;
    }

    final visitors = json['visitors'];
    String? visitorName;
    String? profileEmail;
    String? profileMobile;
    if (visitors is List && visitors.isNotEmpty) {
      final first = visitors.first;
      if (first is Map<String, dynamic>) {
        // visitor name may be at top-level `full_name` or nested under `profile`.
        visitorName = first['full_name']?.toString();
        final profile = first['profile'] is Map<String, dynamic>
            ? first['profile'] as Map<String, dynamic>
            : null;
        profileEmail = profile?['email']?.toString();
        profileMobile = profile?['mobile_number']?.toString();
        visitorName ??= profile?['full_name']?.toString();
      }
    }

    // For display prefer visitor profile email/mobile when available;
    // fall back to host or company fields from API.
    final hostContact = json['host_contact']?.toString();
    final hostUser =
        json['host_user'] is Map<String, dynamic> ? json['host_user'] as Map<String, dynamic> : null;
    final company =
        json['company'] is Map<String, dynamic> ? json['company'] as Map<String, dynamic> : null;

    final displayEmail = profileEmail?.toString().isNotEmpty == true
      ? profileEmail
      : (hostContact ?? hostUser?['username']?.toString() ?? '');
    final displayContact = profileMobile?.toString().isNotEmpty == true
      ? profileMobile
      : (company?['company_name']?.toString() ?? '');
    final visitorCompanyName = company?['company_name']?.toString();

    // If there's no visitor name, fall back to host username or company name
    // so UI doesn't display a null name when `visitors` or `profile` is missing.
    visitorName ??= hostUser?['username']?.toString() ?? visitorCompanyName;

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['created_at'].toString());
    } catch (_) {
      createdAt = DateTime.now();
    }

    DateTime? updatedAt;
    final approvedAtRaw = json['approved_at'];
    final updatedAtRaw = json['updated_at'];
    if (approvedAtRaw != null) {
      try {
        updatedAt = DateTime.parse(approvedAtRaw.toString());
      } catch (_) {}
    }
    updatedAt ??= updatedAtRaw != null
        ? DateTime.tryParse(updatedAtRaw.toString())
        : null;

    ApprovalMode? approvalMode;
    final mode = json['approval_mode']?.toString();
    if (mode == 'security_based') {
      approvalMode = ApprovalMode.security_based;
    } else if (mode == 'host_based') {
      approvalMode = ApprovalMode.host_based;
    }

    final visitId = (json['visit_id'] as num?)?.toInt();
    final approvalStatus = json['approval_status']?.toString();

    DateTime? dateOfVisit;
    final dateOfVisitRaw = json['date_of_visit'];
    if (dateOfVisitRaw != null) {
      dateOfVisit = DateTime.tryParse(dateOfVisitRaw.toString());
    }

    return VisitorRequest(
      id: json['id']?.toString() ?? '',
      email: displayEmail ?? '',
      contactNo: displayContact ?? '',
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rejectRemark: json['approval_remark']?.toString(),
      visitorName: visitorName,
      approvalMode: approvalMode,
      visitId: visitId,
      approvalStatus: approvalStatus,
      dateOfVisit: dateOfVisit,
      purposeOfVisit: json['purpose_of_visit']?.toString(),
      hostName: json['host_name']?.toString() ?? hostUser?['username']?.toString(),
      hostCompanyName: json['host_company_name']?.toString(),
      visitorCompanyName: visitorCompanyName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'contact_no': contactNo,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'reject_remark': rejectRemark,
        'visitor_name': visitorName,
        'visit_id': visitId,
        'approval_status': approvalStatus,
      };

  VisitorRequest copyWith({
    String? id,
    String? email,
    String? contactNo,
    VisitorStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rejectRemark,
    String? visitorName,
    ApprovalMode? approvalMode,
    int? visitId,
    DateTime? dateOfVisit,
    String? purposeOfVisit,
    String? hostName,
    String? hostCompanyName,
    String? visitorCompanyName,
  }) {
    return VisitorRequest(
      id: id ?? this.id,
      email: email ?? this.email,
      contactNo: contactNo ?? this.contactNo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectRemark: rejectRemark ?? this.rejectRemark,
      visitorName: visitorName ?? this.visitorName,
      approvalMode: approvalMode ?? this.approvalMode,
      visitId: visitId ?? this.visitId,
      dateOfVisit: dateOfVisit ?? this.dateOfVisit,
      purposeOfVisit: purposeOfVisit ?? this.purposeOfVisit,
      hostName: hostName ?? this.hostName,
      hostCompanyName: hostCompanyName ?? this.hostCompanyName,
      visitorCompanyName: visitorCompanyName ?? this.visitorCompanyName,
    );
  }
}
