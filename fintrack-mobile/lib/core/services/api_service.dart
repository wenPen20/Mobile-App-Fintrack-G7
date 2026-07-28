import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // --- Authentication ---
  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  Future<void> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
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
      throw Exception('Failed to load transactions');
    }
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> txData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/'),
      headers: _headers,
      body: jsonEncode(txData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create transaction');
    }
  }

  Future<Map<String, dynamic>> updateTransaction(String id, Map<String, dynamic> txData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _headers,
      body: jsonEncode(txData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update transaction');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete transaction');
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
      throw Exception('Failed to load budgets');
    }
  }

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> budgetData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/budgets/'),
      headers: _headers,
      body: jsonEncode(budgetData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to configure budget');
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
      throw Exception('Failed to load categories');
    }
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories/'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create category');
    }
  }

  Future<Map<String, dynamic>> updateCategory(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update category');
    }
  }

  Future<void> deleteCategory(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete category');
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
      throw Exception('Failed to load financial summary');
    }
  }

  // --- Profile & Password Settings ---
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load profile');
    }
  }

  Future<void> updateProfileName(String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/update-name'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update profile name');
    }
  }

  // Compatibility alias used by the unfinished profile screen.
  Future<void> updateName(String name) => updateProfileName(name);

  Future<void> updateOnboarding(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/update-onboarding'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update onboarding data');
    }
  }


  Future<void> confirmPassword(String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/confirm-password'),
      headers: _headers,
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Incorrect password');
    }
  }

  Future<void> updatePassword(String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/update-password'),
      headers: _headers,
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update password');
    }
  }

  // --- AI Assistant ---
  Future<String> sendChatMessage(String message,
      {String sessionId = 'default'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: _headers,
      body: jsonEncode({'message': message, 'session_id': sessionId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['reply'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to reach the assistant');
    }
  }

  Future<List<dynamic>> getChatHistory({String sessionId = 'default'}) async {
    final uri = Uri.parse('$baseUrl/ai/history')
        .replace(queryParameters: {'session_id': sessionId});
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load chat history');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final authState = ref.watch(authProvider);
  return ApiService(
    baseUrl: 'http://localhost:8000',
    token: authState.token,
  );
});
