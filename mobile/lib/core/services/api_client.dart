import "dart:convert";
import "package:http/http.dart" as http;
import "../config/api_config.dart";
import "token_storage.dart";

class ApiClient {
  static Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth, hasBody: true);
    final uri = Uri.parse("${ApiConfig.baseUrl}$path");

    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);
    final uri = Uri.parse("${ApiConfig.baseUrl}$path");

    final response = await http
        .get(
          uri,
          headers: headers,
        )
        .timeout(ApiConfig.timeout);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) async {
    final headers = await _headers(auth: auth);
    final uri = Uri.parse("${ApiConfig.baseUrl}$path");

    final response = await http
        .delete(
          uri,
          headers: headers,
        )
        .timeout(ApiConfig.timeout);

    return _handleResponse(response);
  }

  static Future<Map<String, String>> _headers({
    required bool auth,
    bool hasBody = false,
  }) async {
    final headers = <String, String>{
      "Accept": "application/json",
    };

    if (hasBody) {
      headers["Content-Type"] = "application/json";
    }

    if (auth) {
      final token = await TokenStorage.getToken();

      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {"detail": response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {"data": decoded};
    }

    String message = "Erro inesperado.";

    if (decoded is Map<String, dynamic>) {
      final detail = decoded["detail"];

      if (detail is String) {
        message = detail;
      } else {
        message = detail.toString();
      }
    }

    throw Exception(message);
  }
}

