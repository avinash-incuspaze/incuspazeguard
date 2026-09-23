/// Response from GetAllVisitorsWithVisit API.
class VisitWithVisitors {
  final int visitId;
  final String? purposeOfVisit;
  final String? visitorType;
  final int visitorCount;
  final String centerName;
  final String? companyName;
  final String? hostName;
  final String? dateOfVisit;
  final String? timeOfVisit;
  final List<VisitorInVisit> visitors;

  VisitWithVisitors({
    required this.visitId,
    this.purposeOfVisit,
    this.visitorType,
    required this.visitorCount,
    required this.centerName,
    this.companyName,
    this.hostName,
    this.dateOfVisit,
    this.timeOfVisit,
    required this.visitors,
  });

  factory VisitWithVisitors.fromJson(Map<String, dynamic> json) {
    final visitorsList = json['visitors'] as List<dynamic>? ?? [];
    // Support both flat fields and nested objects for company/host.
    String? parsedCompanyName;
    if (json['company'] is Map<String, dynamic>) {
      parsedCompanyName = (json['company']['company_name'] as String?)?.trim();
    }
    parsedCompanyName ??= json['company_name'] as String?;

    String? parsedHostName;
    if (json['host_user'] is Map<String, dynamic>) {
      parsedHostName = (json['host_user']['username'] as String?)?.trim();
    }
    parsedHostName ??= json['host_name'] as String?;

    return VisitWithVisitors(
      visitId: (json['visit_id'] as num?)?.toInt() ?? 0,
      purposeOfVisit: json['purpose_of_visit'] as String?,
      visitorType: json['visitor_type'] as String?,
      visitorCount: (json['visitor_count'] as num?)?.toInt() ?? 0,
      centerName: (json['center_name'] as String?) ?? '',
      companyName: parsedCompanyName,
      hostName: parsedHostName,
      dateOfVisit: json['date_of_visit'] as String?,
      timeOfVisit: json['time_of_visit'] as String?,
      visitors: visitorsList
          .map((e) => VisitorInVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VisitorInVisit {
  final int visitorId;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? visitorImage;
  final String? idProofType;
  final String? idProof;

  VisitorInVisit({
    required this.visitorId,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.visitorImage,
    this.idProofType,
    this.idProof,
  });

  factory VisitorInVisit.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map<String, dynamic>
      ? json['profile'] as Map<String, dynamic>
      : null;

    return VisitorInVisit(
      visitorId: (json['visitor_id'] as num?)?.toInt() ?? 0,
      fullName: (json['full_name'] as String?) ??
        (profile?['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? (profile?['email'] as String?) ?? '',
      mobileNumber: (json['mobile_number'] as String?) ??
        (profile?['mobile_number'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      checkInTime: json['check_in_time'] != null
        ? DateTime.tryParse(json['check_in_time'] as String)
        : null,
      checkOutTime: json['check_out_time'] != null
        ? DateTime.tryParse(json['check_out_time'] as String)
        : null,
      visitorImage:
        (json['visitor_image'] as String?) ?? (profile?['image'] as String?),
      idProofType: (json['id_proof_type'] as String?) ??
        (profile?['id_proof_type'] as String?),
      idProof: (json['id_proof'] as String?) ?? (profile?['id_proof'] as String?),
    );
  }

  bool get canCheckout => status == 'checked_in';
}

class VisitorsWithVisitResponse {
  final List<VisitWithVisitors> data;
  final VisitorsPagination pagination;

  VisitorsWithVisitResponse({
    required this.data,
    required this.pagination,
  });

  factory VisitorsWithVisitResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final pag = json['pagination'] as Map<String, dynamic>?;
    return VisitorsWithVisitResponse(
      data: dataList
          .map((e) => VisitWithVisitors.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: pag != null
          ? VisitorsPagination.fromJson(pag)
          : VisitorsPagination(currentPage: 1, perPage: 10, total: 0, lastPage: 1),
    );
  }
}

class VisitorsPagination {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  VisitorsPagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory VisitorsPagination.fromJson(Map<String, dynamic> json) {
    return VisitorsPagination(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  bool get hasMore => currentPage < lastPage;
}
