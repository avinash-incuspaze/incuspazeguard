import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app/api/api_endpoints.dart';
import '../models/guard_user.dart';

class AuthService {
  static const _keyToken = 'guard_token';
  static const _keyUser = 'guard_user';

  /// Send OTP to the given email using the same backend as the main app.
  Future<Map<String, dynamic>> sendOtp(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return {
        'success': false,
        'message': 'Please enter your email address',
      };
    }

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.sendOtp),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': trimmed}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] == true;
      return {
        'success': status,
        'message': data['message'] ?? (status ? 'OTP sent successfully' : 'Failed to send OTP'),
        'raw': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Verify OTP and complete login.
  ///
  /// This uses the same /api/verifyOTP endpoint and **allows any role** that
  /// the backend returns (no role restriction here).
  Future<bool> verifyOtpAndLogin(String email, String otp) async {
    final trimmedEmail = email.trim();
    final trimmedOtp = otp.trim();
    if (trimmedEmail.isEmpty || trimmedOtp.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyOtp),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': trimmedEmail,
          'otp': trimmedOtp,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] == true;
      if (!status) {
        return false;
      }

      final token = data['token']?.toString();
      final userData = data['data'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      // Map backend user data into a simple GuardUser for local use.
      // API returns role as { "name": "...", "slug": "..." } and center as { "name", "building", "address" }.
      final roleObj = userData['role'] ?? userData['Role'];
      String? roleName;
      if (roleObj is Map) {
        final m = Map<String, dynamic>.from(roleObj);
        roleName = m['name']?.toString() ?? m['slug']?.toString() ?? m['Name']?.toString();
      } else {
        roleName = roleObj?.toString();
      }

      final centerObj = userData['center'] ?? userData['centre'] ?? userData['Center'] ?? userData['Centre'];
      String? centreName;
      String? building;
      String? address;
      if (centerObj is Map) {
        final cm = Map<String, dynamic>.from(centerObj);
        centreName = cm['name']?.toString() ?? cm['Name']?.toString();
        building = cm['building']?.toString() ?? cm['Building']?.toString();
        address = cm['address']?.toString() ?? cm['Address']?.toString();
      }
      centreName ??= userData['centre_name']?.toString() ?? userData['center_name']?.toString();
      building ??= userData['building']?.toString();
      address ??= userData['address']?.toString();

      final guardUser = GuardUser(
        id: userData['user_id']?.toString() ?? userData['id']?.toString() ?? '',
        email: userData['email']?.toString() ?? trimmedEmail,
        name: userData['username']?.toString(),
        role: roleName,
        centreName: centreName,
        building: building,
        address: address,
      );

      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUser, jsonEncode(guardUser.toJson()));

      // Optionally, you could also store full raw response for debugging/roles:
      // await prefs.setString('guard_raw_login_response', jsonEncode(data));

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken) != null;
  }

  Future<GuardUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUser);
    if (jsonStr == null) return null;
    try {
      return GuardUser.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
