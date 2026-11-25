import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _keyAuthToken = 'auth_jwt_token';

  // Production Live Server Base URL
  static String baseUrl = 'https://api.joynonline.in/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
  }

  static Future<String?> getActiveBusinessId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_business_id');
  }

  static Future<void> saveActiveBusinessId(String businessId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_business_id', businessId);
  }

  static Future<Map<String, String>> _getHeaders([String? businessId]) async {
    final token = await getToken();
    String? bId = businessId;
    if (bId == null || bId.isEmpty) {
      bId = await getActiveBusinessId();
    }
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (bId != null && bId.isNotEmpty) 'x-business-id': bId,
    };
  }

  /// Phase 1: Send SMS OTP via 2Factor.in Gateway
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phoneNumber': phoneNumber}),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network connection issue. Using local fallback.'};
    }
  }

  /// Phase 1: Verify OTP & Retrieve JWT Access Token
  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['accessToken'] != null) {
        await saveToken(data['accessToken']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Verification failed. Using local fallback.'};
    }
  }

  /// Phase 1: Google Authentication / Continue with Google
  static Future<Map<String, dynamic>> googleAuth({
    required String email,
    String? displayName,
    String? photoUrl,
    String? idToken,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'displayName': displayName,
              'photoUrl': photoUrl,
              'idToken': idToken,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        await saveToken(data['token']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 1: GSTIN Auto-Lookup & Address Extraction
  static Future<Map<String, dynamic>> lookupGst(String gstin) async {
    try {
      final headers = await _getHeaders();
      final clean = gstin.trim().toUpperCase();
      final response = await http
          .get(
            Uri.parse('$baseUrl/reports/gst/lookup/$clean'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(response.body);
    } catch (e) {
      final stateCode = gstin.trim().length >= 2 ? gstin.trim().substring(0, 2) : '';
      const stateMap = {
        '01': 'Jammu and Kashmir',
        '02': 'Himachal Pradesh',
        '03': 'Punjab',
        '04': 'Chandigarh',
        '05': 'Uttarakhand',
        '06': 'Haryana',
        '07': 'Delhi',
        '08': 'Rajasthan',
        '09': 'Uttar Pradesh',
        '10': 'Bihar',
        '24': 'Gujarat',
        '27': 'Maharashtra',
        '29': 'Karnataka',
        '33': 'Tamil Nadu',
        '36': 'Telangana',
      };
      final state = stateMap[stateCode] ?? 'Delhi';
      return {
        'success': true,
        'gstin': gstin,
        'state': state,
        'legalName': '',
        'address': '',
        'city': '',
      };
    }
  }

  /// Phase 1: Create Business Profile in Backend
  static Future<Map<String, dynamic>> createBusiness(Map<String, dynamic> businessData) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/business'),
            headers: headers,
            body: jsonEncode(businessData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to connect to cloud backend.'};
    }
  }

  /// Phase 1: Update Business Profile in Backend
  static Future<Map<String, dynamic>> updateBusiness(String businessId, Map<String, dynamic> businessData) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/business/$businessId'),
            headers: headers,
            body: jsonEncode(businessData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update business.'};
    }
  }

  /// Phase 1: Delete Business Profile in Backend
  static Future<Map<String, dynamic>> deleteBusiness(String businessId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/business/$businessId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete business.'};
    }
  }

  /// Phase 1: List My Businesses
  static Future<Map<String, dynamic>> fetchMyBusinesses() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/business/my-businesses'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'businesses': []};
    }
  }

  /// Phase 2: Fetch Inventory Items from Backend
  static Future<Map<String, dynamic>> fetchItems([String? businessId]) async {
    try {
      final headers = await _getHeaders();
      final url = (businessId != null && businessId.isNotEmpty)
          ? '$baseUrl/items?businessId=$businessId'
          : '$baseUrl/items';
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'items': []};
    }
  }

  /// Phase 2: Create Inventory Item in Backend
  static Future<Map<String, dynamic>> createItem(Map<String, dynamic> itemData) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/items'),
            headers: headers,
            body: jsonEncode(itemData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to save item to cloud backend.'};
    }
  }

  /// Update Inventory Item in Backend
  static Future<Map<String, dynamic>> updateItem(String itemId, Map<String, dynamic> itemData) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/items/$itemId'),
            headers: headers,
            body: jsonEncode(itemData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update item in cloud backend.'};
    }
  }

  /// Phase 2: Fetch Parties CRM List from Backend
  static Future<Map<String, dynamic>> fetchParties([String? businessId, String? partyType]) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String>[];
      if (businessId != null && businessId.isNotEmpty) queryParams.add('businessId=$businessId');
      if (partyType != null && partyType.isNotEmpty) queryParams.add('partyType=$partyType');

      final url = queryParams.isNotEmpty
          ? '$baseUrl/parties?${queryParams.join('&')}'
          : '$baseUrl/parties';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'parties': []};
    }
  }

  /// Phase 2: Create Party (Customer / Supplier) in Backend
  static Future<Map<String, dynamic>> createParty(Map<String, dynamic> partyData) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/parties'),
            headers: headers,
            body: jsonEncode(partyData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to save party to cloud backend.'};
    }
  }

  /// Phase 3: Fetch Sales Invoices / Orders from Backend
  static Future<Map<String, dynamic>> fetchSaleOrders([String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final url = (businessId != null && businessId.isNotEmpty)
          ? '$baseUrl/sales/orders?businessId=$businessId'
          : '$baseUrl/sales/orders';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'orders': []};
    }
  }

  /// Phase 3: Create Sales Invoice in Backend (ACID Stock deduction & ledger update)
  static Future<Map<String, dynamic>> createSaleOrder(Map<String, dynamic> saleData, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/sales/orders'),
            headers: headers,
            body: jsonEncode(saleData),
          )
          .timeout(const Duration(seconds: 12));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to sync sales invoice to cloud backend.'};
    }
  }

  /// Phase 3: Fetch Purchase Orders from Backend
  static Future<Map<String, dynamic>> fetchPurchaseOrders([String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final url = (businessId != null && businessId.isNotEmpty)
          ? '$baseUrl/purchases/orders?businessId=$businessId'
          : '$baseUrl/purchases/orders';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'orders': []};
    }
  }

  /// Phase 3: Create Purchase Order in Backend (ACID Stock addition & ledger update)
  static Future<Map<String, dynamic>> createPurchaseOrder(Map<String, dynamic> purchaseData, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/purchases/orders'),
            headers: headers,
            body: jsonEncode(purchaseData),
          )
          .timeout(const Duration(seconds: 12));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to sync purchase order to cloud backend.'};
    }
  }

  /// Phase 3: Fetch Payments Ledger from Backend
  static Future<Map<String, dynamic>> fetchPayments([String? businessId, String? partyId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = <String>[];
      if (businessId != null && businessId.isNotEmpty) queryParams.add('businessId=$businessId');
      if (partyId != null && partyId.isNotEmpty) queryParams.add('partyId=$partyId');

      final url = queryParams.isNotEmpty
          ? '$baseUrl/payments?${queryParams.join('&')}'
          : '$baseUrl/payments';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'payments': []};
    }
  }

  /// Phase 3: Create Payment (In / Out) in Backend (ACID balance update)
  static Future<Map<String, dynamic>> createPayment(Map<String, dynamic> paymentData, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/payments'),
            headers: headers,
            body: jsonEncode(paymentData),
          )
          .timeout(const Duration(seconds: 12));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to sync payment to cloud backend.'};
    }
  }

  /// Phase 4: Rapid Barcode / SKU Item Lookup
  static Future<Map<String, dynamic>> searchBarcode(String code, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(
            Uri.parse('$baseUrl/barcode/search?code=${Uri.encodeComponent(code)}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Barcode search timed out.'};
    }
  }

  /// Phase 4: Generate Unique Standard EAN-13 Barcode
  static Future<Map<String, dynamic>> generateUniqueBarcode([String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/barcode/generate'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to generate barcode.'};
    }
  }

  /// Phase 4: Get WhatsApp Share Link with Public Invoice View URL
  static Future<Map<String, dynamic>> getWhatsAppShareLink(String orderId, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(
            Uri.parse('$baseUrl/sales/orders/$orderId/whatsapp-share'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to generate WhatsApp share link.'};
    }
  }

  /// Phase 4: Public or Streamed Invoice PDF URL
  static String getInvoicePdfUrl(String orderId) {
    return '$baseUrl/sales/orders/$orderId/pdf';
  }

  // ==========================================
  // PHASE 5: TEAM MANAGEMENT & ROLES (RBAC)
  // ==========================================

  /// Phase 5: Fetch All Roles
  static Future<Map<String, dynamic>> fetchRoles([String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(
            Uri.parse('$baseUrl/roles'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'roles': []};
    }
  }

  /// Phase 5: Create Custom Role
  static Future<Map<String, dynamic>> createRole(Map<String, dynamic> roleData, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/roles'),
            headers: headers,
            body: jsonEncode(roleData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to create role.'};
    }
  }

  /// Phase 5: Update Role
  static Future<Map<String, dynamic>> updateRole(String roleId, Map<String, dynamic> roleData, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .put(
            Uri.parse('$baseUrl/roles/$roleId'),
            headers: headers,
            body: jsonEncode(roleData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update role.'};
    }
  }

  /// Phase 5: Delete Role
  static Future<Map<String, dynamic>> deleteRole(String roleId, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .delete(
            Uri.parse('$baseUrl/roles/$roleId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete role.'};
    }
  }

  /// Phase 5: Fetch Team Members
  static Future<Map<String, dynamic>> fetchTeamMembers([String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(
            Uri.parse('$baseUrl/team-members'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'teamMembers': []};
    }
  }

  /// Phase 5: Create Team Member
  static Future<Map<String, dynamic>> createTeamMember(Map<String, dynamic> memberData, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/team-members'),
            headers: headers,
            body: jsonEncode(memberData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to add team member.'};
    }
  }

  /// Phase 5: Update Team Member
  static Future<Map<String, dynamic>> updateTeamMember(String memberId, Map<String, dynamic> memberData, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .put(
            Uri.parse('$baseUrl/team-members/$memberId'),
            headers: headers,
            body: jsonEncode(memberData),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update team member.'};
    }
  }

  /// Phase 5: Toggle Member Status (Active / Inactive)
  static Future<Map<String, dynamic>> toggleTeamMemberStatus(String memberId, bool isActive, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .patch(
            Uri.parse('$baseUrl/team-members/$memberId/toggle-status'),
            headers: headers,
            body: jsonEncode({'isActive': isActive}),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update member status.'};
    }
  }

  /// Phase 5: Delete Team Member
  static Future<Map<String, dynamic>> deleteTeamMember(String memberId, [String? businessId]) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .delete(
            Uri.parse('$baseUrl/team-members/$memberId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete team member.'};
    }
  }

  /// Phase 5: Fetch Team Member Activity Logs
  static Future<Map<String, dynamic>> fetchMemberActivityLogs(
    String memberId, {
    String period = '1month',
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(
            Uri.parse('$baseUrl/team-members/$memberId/activity-logs?period=$period'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'logs': []};
    }
  }

  // =====================================================================
  // PHASE 6: FINANCIAL REPORTS & ACCOUNTING APIS
  // =====================================================================

  /// Phase 6: Fetch Day Book
  static Future<Map<String, dynamic>> fetchDayBook({
    String? date,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final query = date != null ? '?date=$date' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/reports/daybook$query'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'summary': {}, 'transactions': []};
    }
  }

  /// Phase 6: Fetch Profit and Loss Statement
  static Future<Map<String, dynamic>> fetchProfitAndLoss({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final params = <String>[];
      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/reports/profit-loss$query'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'grossProfit': 0.0, 'netProfit': 0.0, 'rows': []};
    }
  }

  /// Phase 6: Fetch Balance Sheet
  static Future<Map<String, dynamic>> fetchBalanceSheet({
    String? asOfDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final query = asOfDate != null ? '?asOfDate=$asOfDate' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/reports/balance-sheet$query'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'totalAssets': 0.0,
        'totalLiabilities': 0.0,
        'liabilityCards': [],
        'assetCards': []
      };
    }
  }

  /// Phase 6: Fetch Cash Flow
  static Future<Map<String, dynamic>> fetchCashFlow({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final params = <String>[];
      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/reports/cashflow$query'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'inflow': {}, 'outflow': {}, 'netCashFlow': 0.0};
    }
  }

  /// Phase 6: Fetch Bill-Wise Profit
  static Future<Map<String, dynamic>> fetchBillWiseProfit({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final params = <String>[];
      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/reports/bill-wise-profit$query'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'bills': [], 'totalProfit': 0.0, 'averageMargin': 0.0};
    }
  }

  /// Phase 6: Fetch Party Statement
  static Future<Map<String, dynamic>> fetchPartyStatement({
    required dynamic partyId,
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final params = <String>[];
      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/reports/party-statement/$partyId$query'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'ledger': []};
    }
  }

  /// Phase 6: Fetch All Parties Report
  static Future<Map<String, dynamic>> fetchAllPartiesReport({
    String? asOfDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final query = asOfDate != null ? '?asOfDate=$asOfDate' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/reports/parties$query'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'parties': []};
    }
  }

  /// Phase 6: Fetch GST Summary
  static Future<Map<String, dynamic>> fetchGstSummary({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final params = <String>[];
      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/reports/gst/summary$query'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false};
    }
  }

  /// Executive KPIs & Real-Time Analytics Overview
  static Future<Map<String, dynamic>> fetchExecutiveAnalytics({
    String? startDate,
    String? endDate,
    String? partyId,
    String? category,
    String? paymentMode,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (partyId != null) queryParams['partyId'] = partyId;
      if (category != null) queryParams['category'] = category;
      if (paymentMode != null) queryParams['paymentMode'] = paymentMode;

      final uri = Uri.parse('$baseUrl/reports/analytics/overview').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Deep Item Sales Velocity & Dead Stock Analytics
  static Future<Map<String, dynamic>> fetchItemAnalytics({
    String? startDate,
    String? endDate,
    String? category,
    String? search,
    String? type,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse('$baseUrl/reports/analytics/items').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'items': []};
    }
  }

  /// Deep Party Analytics & Credit Aging Risk
  static Future<Map<String, dynamic>> fetchPartyAnalytics({
    String? startDate,
    String? endDate,
    String? type,
    String? search,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (type != null) queryParams['type'] = type;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/reports/analytics/parties').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'parties': []};
    }
  }

  /// Deep Inventory Health & Reorder Alerts
  static Future<Map<String, dynamic>> fetchInventoryHealth({
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final uri = Uri.parse('$baseUrl/reports/analytics/inventory');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ===========================================================================
  // PHASE 7: OFFLINE-FIRST DELTA SYNC & ENTERPRISE CLOUD BACKUP ENGINES
  // ===========================================================================

  /// Phase 7: Push local mutations delta to server
  static Future<Map<String, dynamic>> pushDeltaSync({
    required Map<String, dynamic> mutations,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/sync/push'),
            headers: headers,
            body: jsonEncode({'mutations': mutations}),
          )
          .timeout(const Duration(seconds: 25));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 7: Pull incremental delta from server since timestamp
  static Future<Map<String, dynamic>> pullDeltaSync({
    String? since,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final query = since != null && since.isNotEmpty ? '?since=$since' : '';
      final response = await http
          .get(Uri.parse('$baseUrl/sync/pull$query'), headers: headers)
          .timeout(const Duration(seconds: 25));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 7: Create Enterprise Cloud Backup snapshot
  static Future<Map<String, dynamic>> createCloudBackup({
    String? backupName,
    String? deviceName,
    Map<String, dynamic>? data,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final payload = <String, dynamic>{};
      if (backupName != null) payload['backupName'] = backupName;
      if (deviceName != null) payload['deviceName'] = deviceName;
      if (data != null) payload['data'] = data;
      final response = await http
          .post(
            Uri.parse('$baseUrl/backup/create'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 7: List all available Cloud Backups for business
  static Future<Map<String, dynamic>> listCloudBackups({
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(Uri.parse('$baseUrl/backup/list'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'backups': []};
    }
  }

  /// Phase 7: Get full Cloud Backup Details by ID
  static Future<Map<String, dynamic>> getCloudBackupDetails({
    required String backupId,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(Uri.parse('$baseUrl/backup/$backupId'), headers: headers)
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 7: Restore Cloud Backup Snapshot
  static Future<Map<String, dynamic>> restoreCloudBackup({
    required String backupId,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/backup/restore/$backupId'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 7: Delete Cloud Backup Snapshot
  static Future<Map<String, dynamic>> deleteCloudBackup({
    required String backupId,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .delete(Uri.parse('$baseUrl/backup/$backupId'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================================
  // PHASE 8: INVOICE BRANDING, BANKING & DYNAMIC UPI QR
  // ============================================================================

  /// Phase 8: Fetch Available Invoice Themes and Color Presets
  static Future<Map<String, dynamic>> getInvoiceThemes() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/business/invoice-themes'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'themes': [], 'colorPresets': []};
    }
  }

  /// Phase 8: Fetch Detailed Business Profile with Branding & Banking
  static Future<Map<String, dynamic>> getBusinessProfile({String? businessId}) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(Uri.parse('$baseUrl/business/profile'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 8: Update Business Branding, Bank Details & Theme Customization
  static Future<Map<String, dynamic>> updateBusinessBranding({
    required Map<String, dynamic> brandingData,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .put(
            Uri.parse('$baseUrl/business/branding'),
            headers: headers,
            body: jsonEncode(brandingData),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 8: Upload Business Logo (Base64 / Data URI / URL)
  static Future<Map<String, dynamic>> uploadBusinessLogo({
    required String logoData,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/business/upload-logo'),
            headers: headers,
            body: jsonEncode({'logo': logoData}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 8: Upload Business Digital Signature
  static Future<Map<String, dynamic>> uploadBusinessSignature({
    required String signatureData,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/business/upload-signature'),
            headers: headers,
            body: jsonEncode({'signature': signatureData}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==========================================
  // PHASE 9: NOTIFICATIONS & PAYMENT REMINDERS
  // ==========================================

  /// Phase 9: Register FCM Device Token for Push Notifications
  static Future<Map<String, dynamic>> registerDeviceToken(
    String token, {
    String deviceType = 'android',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/register-token'),
            headers: headers,
            body: jsonEncode({'token': token, 'deviceType': deviceType}),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 9: Fetch In-App Notifications for Current Business
  static Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    String? type,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
      };
      final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'notifications': [], 'unreadCount': 0};
    }
  }

  /// Phase 9: Mark Single Notification as Read
  static Future<Map<String, dynamic>> markNotificationRead(
    String notificationId, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .put(
            Uri.parse('$baseUrl/notifications/$notificationId/read'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 9: Mark All Notifications as Read
  static Future<Map<String, dynamic>> markAllNotificationsRead({
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .put(
            Uri.parse('$baseUrl/notifications/read-all'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 9: Delete Notification
  static Future<Map<String, dynamic>> deleteNotification(
    String notificationId, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .delete(
            Uri.parse('$baseUrl/notifications/$notificationId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 9: Check & Auto-Generate Low Stock Notifications
  static Future<Map<String, dynamic>> checkLowStockAlerts({
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/check-low-stock'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 9: Send Custom Notification
  static Future<Map<String, dynamic>> createCustomNotification({
    required String title,
    required String body,
    String type = 'SYSTEM',
    Map<String, dynamic>? data,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/send'),
            headers: headers,
            body: jsonEncode({
              'title': title,
              'body': body,
              'type': type,
              'data': data ?? {},
            }),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 9: Get Overdue Debtors (Customers with Pending Receivables)
  static Future<Map<String, dynamic>> getOverdueDebtors({
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(
            Uri.parse('$baseUrl/reminders/overdue'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'debtors': [], 'totalOverdueAmount': 0};
    }
  }

  /// Phase 9: Send Payment Reminder (Generates WhatsApp text, UPI deep link & logs record)
  static Future<Map<String, dynamic>> sendPaymentReminder({
    required String partyId,
    String channel = 'WHATSAPP',
    String? customNote,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/reminders/send'),
            headers: headers,
            body: jsonEncode({
              'partyId': partyId,
              'channel': channel,
              'customNote': ?customNote,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 9: List Payment Reminders Audit History
  static Future<Map<String, dynamic>> getRemindersHistory({
    int limit = 50,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(
            Uri.parse('$baseUrl/reminders/history?limit=$limit'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'history': []};
    }
  }

  /// Phase 9: Trigger Automated Batch Reminders Dispatch
  static Future<Map<String, dynamic>> triggerBatchAutomatedReminders({
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/reminders/auto-dispatch'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 25));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==========================================
  // PHASE 10: ADVANCED GST FILING & EXPENSES
  // ==========================================

  /// Phase 10: Fetch GSTR-1 Outward Supplies Return
  static Future<Map<String, dynamic>> getGstr1Report({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = {
        'startDate': ?startDate,
        'endDate': ?endDate,
      };
      final uri = Uri.parse('$baseUrl/reports/gst/gstr-1').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 10: Fetch GSTR-2 Inward Supplies (Purchases ITC) Return
  static Future<Map<String, dynamic>> getGstr2Report({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = {
        'startDate': ?startDate,
        'endDate': ?endDate,
      };
      final uri = Uri.parse('$baseUrl/reports/gst/gstr-2').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 10: Fetch GSTR-3B Monthly Summary Return
  static Future<Map<String, dynamic>> getGstr3bReport({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = {
        'startDate': ?startDate,
        'endDate': ?endDate,
      };
      final uri = Uri.parse('$baseUrl/reports/gst/gstr-3b').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 10: Fetch GSTR-9 Annual Return
  static Future<Map<String, dynamic>> getGstr9Report({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = {
        'startDate': ?startDate,
        'endDate': ?endDate,
      };
      final uri = Uri.parse('$baseUrl/reports/gst/gstr-9').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 10: Fetch HSN-Wise Sales & Tax Breakdown
  static Future<Map<String, dynamic>> getHsnSummaryReport({
    String? startDate,
    String? endDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = {
        'startDate': ?startDate,
        'endDate': ?endDate,
      };
      final uri = Uri.parse('$baseUrl/reports/gst/hsn-summary').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'hsnSummary': []};
    }
  }

  /// All Transactions Report (Unified Sales, Purchases, Payments)
  static Future<Map<String, dynamic>> getAllTransactionsReport({
    String? startDate,
    String? endDate,
    String? partyId,
    String? txnType,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (partyId != null) queryParams['partyId'] = partyId;
      if (txnType != null) queryParams['txnType'] = txnType;

      final uri = Uri.parse('$baseUrl/reports/all-transactions').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'transactions': []};
    }
  }

  /// Phase 10: List Expenses
  static Future<Map<String, dynamic>> getExpenses({
    String? category,
    String? startDate,
    String? endDate,
    int limit = 100,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = {
        'category': ?category,
        'startDate': ?startDate,
        'endDate': ?endDate,
        'limit': limit.toString(),
      };
      final uri = Uri.parse('$baseUrl/expenses').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'expenses': [], 'totalAmount': 0};
    }
  }

  /// Phase 10: Record New Operating Expense
  static Future<Map<String, dynamic>> createExpense({
    required String category,
    required double amount,
    String type = 'Indirect',
    String paymentMode = 'CASH',
    String? notes,
    String? expenseDate,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/expenses'),
            headers: headers,
            body: jsonEncode({
              'category': category,
              'amount': amount,
              'type': type,
              'paymentMode': paymentMode,
              'notes': ?notes,
              'expenseDate': ?expenseDate,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 10: Delete Expense
  static Future<Map<String, dynamic>> deleteExpense(
    String expenseId, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .delete(
            Uri.parse('$baseUrl/expenses/$expenseId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 10: Get Expense Summary & Category Breakdown
  static Future<Map<String, dynamic>> getExpenseSummary({
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(
            Uri.parse('$baseUrl/expenses/summary'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'categories': [], 'grandTotal': 0};
    }
  }

  // ============================================================================
  // PHASE 11: QUOTATIONS / ESTIMATES & SALES / PURCHASE RETURNS
  // ============================================================================

  /// Phase 11: List Quotations / Estimates
  static Future<Map<String, dynamic>> getQuotations({
    String? status,
    int limit = 100,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final queryParams = {
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit.toString(),
      };
      final uri = Uri.parse('$baseUrl/quotations').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'quotations': []};
    }
  }

  /// Phase 11: Get Quotation by ID
  static Future<Map<String, dynamic>> getQuotationById(
    String id, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(Uri.parse('$baseUrl/quotations/$id'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 11: Create Quotation / Estimate
  static Future<Map<String, dynamic>> createQuotation(
    Map<String, dynamic> quotationData, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/quotations'),
            headers: headers,
            body: jsonEncode(quotationData),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 11: Update Quotation Status
  static Future<Map<String, dynamic>> updateQuotationStatus(
    String id,
    String status, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .put(
            Uri.parse('$baseUrl/quotations/$id/status'),
            headers: headers,
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 11: Convert Quotation to Tax Invoice (Atomic Stock & Number Generation)
  static Future<Map<String, dynamic>> convertQuotationToInvoice(
    String id, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/quotations/$id/convert-to-invoice'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 25));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 11: List Credit Notes (Sales Return)
  static Future<Map<String, dynamic>> getCreditNotes({
    int limit = 100,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final uri = Uri.parse('$baseUrl/credit-notes').replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'creditNotes': []};
    }
  }

  /// Phase 11: Create Credit Note (Sales Return -> Stock Restored)
  static Future<Map<String, dynamic>> createCreditNote(
    Map<String, dynamic> noteData, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/credit-notes'),
            headers: headers,
            body: jsonEncode(noteData),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 11: List Debit Notes (Purchase Return)
  static Future<Map<String, dynamic>> getDebitNotes({
    int limit = 100,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final uri = Uri.parse('$baseUrl/debit-notes').replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'debitNotes': []};
    }
  }

  /// Phase 11: Create Debit Note (Purchase Return -> Stock Deducted)
  static Future<Map<String, dynamic>> createDebitNote(
    Map<String, dynamic> noteData, {
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/debit-notes'),
            headers: headers,
            body: jsonEncode(noteData),
          )
          .timeout(const Duration(seconds: 20));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================================
  // PHASE 12: AUTOMATED CLOUD BACKUP CRON & SYSTEM TELEMETRY
  // ============================================================================

  /// Phase 12: Get Cloud Server Health & DB Latency
  static Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'OFFLINE', 'message': e.toString()};
    }
  }

  /// Phase 12: Get Cloud Telemetry (Businesses, Catalog, Invoices, Backups)
  static Future<Map<String, dynamic>> getSystemTelemetry({String? businessId}) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(Uri.parse('$baseUrl/system/telemetry'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 12: Get Automated Backup Settings (Schedule & Retention)
  static Future<Map<String, dynamic>> getBackupSettings({String? businessId}) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(Uri.parse('$baseUrl/backup/settings'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'settings': {'autoBackupEnabled': true, 'frequency': 'DAILY', 'retentionDays': 30}
      };
    }
  }

  /// Phase 12: Update Automated Backup Settings
  static Future<Map<String, dynamic>> updateBackupSettings({
    required bool autoBackupEnabled,
    required String frequency,
    int retentionDays = 30,
    String? businessId,
  }) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .put(
            Uri.parse('$baseUrl/backup/settings'),
            headers: headers,
            body: jsonEncode({
              'autoBackupEnabled': autoBackupEnabled,
              'frequency': frequency,
              'retentionDays': retentionDays,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 12: Trigger Automated Backup Cron Immediately
  static Future<Map<String, dynamic>> triggerCronBackup({String? businessId}) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .post(
            Uri.parse('$baseUrl/backup/trigger-cron'),
            headers: headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Phase 12: Download Raw Backup Snapshot
  static Future<String?> downloadBackup(String backupId, {String? businessId}) async {
    try {
      final headers = await _getHeaders(businessId);
      final response = await http
          .get(Uri.parse('$baseUrl/backup/$backupId/download'), headers: headers)
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
