import "dart:convert";
import "package:http/http.dart" as http;
import "../config/api_config.dart";
import "token_storage.dart";

class EmailNotVerifiedException implements Exception {
  final String message;
  EmailNotVerifiedException(this.message);
  @override
  String toString() => "EmailNotVerifiedException: $message";
}

class ApiClient {
  static Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    bool auth = false,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}$path");
    final headers = await _headers(auth: auth, hasBody: true);
    var response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(ApiConfig.timeout);
    if (response.statusCode == 401 && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final newHeaders = await _headers(auth: true, hasBody: true);
        response = await http.post(uri, headers: newHeaders, body: jsonEncode(body)).timeout(ApiConfig.timeout);
      }
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}$path");
    final headers = await _headers(auth: auth);
    var response = await http.get(uri, headers: headers).timeout(ApiConfig.timeout);
    if (response.statusCode == 401 && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final newHeaders = await _headers(auth: true);
        response = await http.get(uri, headers: newHeaders).timeout(ApiConfig.timeout);
      }
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}$path");
    final headers = await _headers(auth: auth);
    var response = await http.delete(uri, headers: headers).timeout(ApiConfig.timeout);
    if (response.statusCode == 401 && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final newHeaders = await _headers(auth: true);
        response = await http.delete(uri, headers: newHeaders).timeout(ApiConfig.timeout);
      }
    }
    return _handleResponse(response);
  }

  static Future<bool> _tryRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/auth/refresh");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      ).timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final name = await TokenStorage.getName() ?? "";
        final email = await TokenStorage.getEmail() ?? "";
        await TokenStorage.saveSession(
          token: data["access_token"],
          refreshToken: data["refresh_token"],
          name: name,
          email: email,
        );
        return true;
      }
    } catch (_) {}
    await TokenStorage.clear();
    return false;
  }

  static Future<Map<String, String>> _headers({
    required bool auth,
    bool hasBody = false,
  }) async {
    final headers = <String, String>{"Accept": "application/json"};
    if (hasBody) headers["Content-Type"] = "application/json";
    if (auth) {
      final token = await TokenStorage.getToken();
      if (token != null) headers["Authorization"] = "Bearer $token";
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
      if (decoded is Map<String, dynamic>) return decoded;
      return {"data": decoded};
    }
    String message = "Erro inesperado.";
    if (decoded is Map<String, dynamic>) {
      final detail = decoded["detail"];
      message = detail is String ? detail : detail.toString();
    }

    // Detecta bloqueio por e-mail não verificado
    if (response.statusCode == 403 && message == "EMAIL_NOT_VERIFIED") {
      throw EmailNotVerifiedException("Verifique seu e-mail para continuar.");
    }

    throw Exception(message);
  }
}
