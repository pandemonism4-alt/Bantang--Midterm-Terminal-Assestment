import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resource_model.dart';

/// Service for consuming external RESTful APIs.
/// Integrates with JSONPlaceholder for resource data.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Changed to a more reliable placeholder API if JSONPlaceholder is failing
  // or simply ensured the URL is correct for the request.
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Fetches resource data (todos) from the external API.
  Future<List<ResourceModel>> fetchResources({int limit = 50}) async {
    try {
      // Adding a common browser-like User-Agent to avoid 403 blocks
      final response = await http.get(
        Uri.parse('$_baseUrl/todos?_limit=$limit'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return ResourceModel.fromJsonList(data);
      } else if (response.statusCode == 403) {
        throw Exception('Access Forbidden (403): The API is blocking the request. This often happens on emulators without proper network setup.');
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } catch (e) {
      throw Exception('Failed to load resources: $e');
    }
  }
}
