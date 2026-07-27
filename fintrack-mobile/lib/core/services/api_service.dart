import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../features/auth/providers/auth_provider.dart';

class ApiService {
  final String baseUrl;
  final String? token;

  ApiService({
    required this.baseUrl,
    this.token,
  });

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- Transactions ---
  Future<List<dynamic>> getTransactions({int? month, int? year, String? type}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();
    if (type != null) queryParams['transaction_type'] = type;

    final uri = Uri.parse('$baseUrl/transactions/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {};
    }
  }

  // --- Categories ---
  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      return [];
    }
  }

  // --- Budgets ---
  Future<List<dynamic>> getBudgets({int? month, int? year}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse('$baseUrl/budgets/').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      return [];
    }
  }

  // --- Summary ---
  Future<Map<String, dynamic>> getSummary(int month, int year) async {
    final uri = Uri.parse('$baseUrl/summary/').replace(queryParameters: {
      'month': month.toString(),
      'year': year.toString(),
    });
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {
        'total_income': 0.0,
        'total_expenses': 0.0,
        'net': 0.0,
        'per_category_breakdown': {},
      };
    }
  }

  // --- Profile & Onboarding ---
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return {'name': 'User', 'onboarding_completed': false};
    }
  }

  Future<void> updateName(String name) async {
    await http.put(
      Uri.parse('$baseUrl/profile/update-name'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
  }

  Future<void> updateOnboarding(Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('$baseUrl/profile/update-onboarding'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final authState = ref.watch(authProvider);
  return ApiService(
    baseUrl: 'http://localhost:8000',
    token: authState.token,
  );
});
