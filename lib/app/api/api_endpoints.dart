class ApiEndpoints {
  // Use same backend base URL as main Incuspaze app
  static const String baseUrl = 'https://app.incuspaze.com/backend';

  // Authentication endpoints
  static const String sendOtp = '$baseUrl/api/getotp';
  static const String verifyOtp = '$baseUrl/api/verifyOTP';

  // Reception / guard portal endpoints
  static const String receptionDropInsManual =
      '$baseUrl/api/reception/drop-ins/manual';

  static String receptionDropInApproval(String id) =>
      '$baseUrl/api/reception/drop-ins/$id/approval';

  // Visitors list (for guard checkout)
  static const String getAllVisitorsWithVisit =
      '$baseUrl/api/visitors/GetAllVisitorsWithVisit';
  static const String visitorCheckout = '$baseUrl/api/visitor/checkout';
}

