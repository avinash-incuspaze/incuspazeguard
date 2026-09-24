import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app/api/api_endpoints.dart';
import '../models/visitor_request.dart';
import '../models/visit_with_visitors.dart';

/// One page of pending drop-ins from the API (status=pending, single call).
class PendingDropInsPage {
  final List<VisitorRequest> items;
  final bool hasMore;
  final int currentPage;

  PendingDropInsPage({
    required this.items,
    required this.hasMore,
    required this.currentPage,
  });
}

class VisitorService {
  static const _keyToken = 'guard_token';

  /// Result of a single paginated page of pending drop-ins.
  static List<VisitorRequest> parsePendingPageResponse(
    Map<String, dynamic> data,
  ) {

    final paginationData = data['data'] as Map<String, dynamic>?;

    final list = paginationData?['data'] as List<dynamic>? ?? [];
  //  final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map(
          (e) =>
              VisitorRequest.fromDropInBackend(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// Fetches one page of pending drop-ins (single API call: status=pending).
  /// Use for pagination / load more. Does not filter by approval_mode.
  Future<PendingDropInsPage> getPendingPage({
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return PendingDropInsPage(items: [], hasMore: false, currentPage: page);
    }
    final path =
        '${ApiEndpoints.receptionDropInsManual}?per_page=$perPage&page=$page';
    final uri = Uri.parse(path);
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        return PendingDropInsPage(items: [], hasMore: false, currentPage: page);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != true) {
        return PendingDropInsPage(items: [], hasMore: false, currentPage: page);
      }
      final items = parsePendingPageResponse(data);
      final hasMore = _hasMoreFromResponse(data, page, perPage, items.length);
      return PendingDropInsPage(
        items: items,
        hasMore: hasMore,
        currentPage: page,
      );
    } catch (_) {
      return PendingDropInsPage(items: [], hasMore: false, currentPage: page);
    }
  }

  bool _hasMoreFromResponse(
    Map<String, dynamic> data,
    int currentPage,
    int perPage,
    int itemsLength,
  ) {
    final meta = data['meta'] as Map<String, dynamic>?;
    final pagination = data['pagination'] as Map<String, dynamic>?;
    final map = meta ?? pagination;
    if (map != null) {
      final lastPage = (map['last_page'] as num?)?.toInt();
      final total = (map['total'] as num?)?.toInt();
      if (lastPage != null && lastPage > 0) return currentPage < lastPage;
      if (total != null && total > 0) {
        return (currentPage * perPage) < total;
      }
    }
    return itemsLength >= perPage;
  }

  /// Fetch pending drop-ins from backend (both security_based and host_based).
  /// Fetches first page only; for pagination use [getPendingPage] and load more.
  Future<List<VisitorRequest>> getPending({int page = 1, int perPage = 10}) async {
    final security = await _fetchDropInsByStatus(
      status: 'pending',
      page: page,
      perPage: perPage,
      approvalMode: 'security_based',
    );
    final host = await _fetchDropInsByStatus(
      status: 'pending',
      page: page,
      perPage: perPage,
      approvalMode: 'host_based',
    );
    final list = <VisitorRequest>[...security, ...host]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Fetches one page of approved drop-ins (single API call: status=approved).
  /// Use for pagination / load more in date-wise history.
  Future<PendingDropInsPage> getApprovedPage({
    int page = 1,
    int perPage = 10,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return PendingDropInsPage(items: [], hasMore: false, currentPage: page);
    }
    final path =
        '${ApiEndpoints.receptionDropInsManual}?status=approved&per_page=$perPage&page=$page';
    final uri = Uri.parse(path);
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        return PendingDropInsPage(items: [], hasMore: false, currentPage: page);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != true) {
        return PendingDropInsPage(items: [], hasMore: false, currentPage: page);
      }
      final items = parsePendingPageResponse(data);
      final sorted = List<VisitorRequest>.from(items)
        ..sort(
          (a, b) =>
              (b.updatedAt ?? b.createdAt)
                  .compareTo(a.updatedAt ?? a.createdAt),
        );
      final hasMore = _hasMoreFromResponse(data, page, perPage, items.length);
      return PendingDropInsPage(
        items: sorted,
        hasMore: hasMore,
        currentPage: page,
      );
    } catch (_) {
      return PendingDropInsPage(items: [], hasMore: false, currentPage: page);
    }
  }

  /// Fetch all approved drop-ins (both security_based and host_based). No date filter.
  Future<List<VisitorRequest>> getApproved({int perPage = 100}) async {
    final security = await _fetchDropInsByStatus(
      status: 'approved',
      page: 1,
      perPage: perPage,
      approvalMode: 'security_based',
    );
    final host = await _fetchDropInsByStatus(
      status: 'approved',
      page: 1,
      perPage: perPage,
      approvalMode: 'host_based',
    );
    final all = <VisitorRequest>[...security, ...host]
      ..sort(
        (a, b) =>
            (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt),
      );
    return all;
  }

  /// Fetch rejected visitors for a particular date (date filtered on client).
  Future<List<VisitorRequest>> getRejectedByDate(DateTime date) async {
    final all = await _fetchDropInsByStatus(status: 'rejected', perPage: 100);
    return all
        .where(
          (v) =>
              v.status == VisitorStatus.rejected &&
              _isSameDay(v.updatedAt ?? v.createdAt, date),
        )
        .toList()
      ..sort(
        (a, b) => (b.updatedAt ?? b.createdAt)
            .compareTo(a.updatedAt ?? a.createdAt),
      );
  }

  /// Approve a drop-in with mandatory remark.
  // Future<void> approve(String visitorId, String remark) async {
  //   await _patchApproval(visitorId, status: 'approved', remark: remark);
  // }

  Future<bool> approve(String visitorId, String remark) async {
  return await _patchApproval(
    visitorId,
    status: 'approved',
    remark: remark,
  );
}

  /// Reject a drop-in with mandatory remark.
  Future<void> reject(String visitorId, String remark) async {
    await _patchApproval(visitorId, status: 'rejected', remark: remark);
  }

  Future<List<VisitorRequest>> _fetchDropInsByStatus({
    required String status,
    int page = 1,
    int perPage = 10,
    String? approvalMode,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return [];
    }

    var path = '${ApiEndpoints.receptionDropInsManual}?status=$status&per_page=$perPage&page=$page';
    if (approvalMode != null && approvalMode.isNotEmpty) {
      path += '&approval_mode=$approvalMode';
    }
    final uri = Uri.parse(path);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != true) {
        return [];
      }

      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .map(
            (e) => VisitorRequest.fromDropInBackend(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

Future<bool> _patchApproval(
  String visitorId, {
  required String status,
  required String remark,
}) async {
  final token = await _getToken();

  if (token == null) {
    return false;
  }

  final uri = Uri.parse(
    ApiEndpoints.receptionDropInApproval(visitorId),
  );

  try {
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
        'remark': remark,
      }),
    );

    debugPrint('Approval response: ${response.body}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return data['status'] == true;
  } catch (e) {
    debugPrint('Approval error: $e');
    return false;
  }
}

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Fetch all visits with visitors (paginated). Used for visitors list / checkout.
  Future<VisitorsWithVisitResponse?> getVisitorsWithVisit({
    int page = 1,
    int perPage = 10,
  }) async {
    // DEBUG: local dummy was used for UI testing. Disable to call real API.
    const _useLocalDummy = false;
    if (kDebugMode && _useLocalDummy) {
      final Map<String, dynamic> dummy = {
        'data': [
          {
            "id": 7,
            "visitor_type": "drop_in",
            "purpose_of_visit": "New panel test",
            "date_of_visit": "2026-08-29T18:30:00.000000Z",
            "time_of_visit": "23:02:00",
            "center_id": 2,
            "company_id": 1,
            "host": 9,
            "host_name": "Himanshu",
            "host_email": "hi************i@incuspaze.com",
            "host_company_name": "Incuspaze",
            "visitor_count": 1,
            "approval_mode": "security_based",
            "approval_status": "pending",
            "status": "pending",
            "created_at": "2026-08-30T17:30:04.000000Z",
            "updated_at": "2026-08-30T17:30:04.000000Z",
            "visitors": [
              {
                "id": 6,
                "visit_id": 7,
                "visitor_profile_id": 6,
                "visitor_type": "drop_in",
                "status": "requested",
                "created_at": "2026-08-30T17:30:04.000000Z",
                "updated_at": "2026-08-30T17:30:04.000000Z",
                "profile": {
                  "id": 6,
                  "full_name": "Avinash",
                  "email": "Avinash.tiwari@incuspaze.com",
                  "mobile_number": "9810252878",
                  "company_info": "incuspaze",
                  "image": "visitor_profiles/photos/sample.jpg"
                }
              }
            ],
            "company": {"id": 1, "company_name": "Incuspaze"},
            "host_user": {"id": 9, "username": "Himanshu Papnai"}
          }
        ],
        'pagination': {
          'current_page': 1,
          'per_page': perPage,
          'total': 1,
          'last_page': 1,
        }
      };
      return VisitorsWithVisitResponse.fromJson(dummy);
    }
    final token = await _getToken();
    if (token == null) return null;

    final uri = Uri.parse(ApiEndpoints.getAllVisitorsWithVisit)
        .replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != true) return null;

      return VisitorsWithVisitResponse.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Check out a visitor. Requires visit_id and visitor_id.
  Future<bool> checkout({required int visitId, required int visitorId}) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.visitorCheckout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'visit_id': visitId,
          'visitor_id': visitorId,
        }),
      );
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['status'] == true;
    } catch (_) {
      return false;
    }
  }
}
