import "dart:convert";
import "dart:async";
import "package:http/http.dart" as http;
import "../config/api_config.dart";
import "token_storage.dart";

class EmailNotVerifiedException implements Exception {
  final String message;
  EmailNotVerifiedException(this.message);
  @override
  String toString() => message;
}

class TrialExpiredException implements Exception {
  final String message;
  TrialExpiredException(this.message);
  @override
  String toString() => message;
}

class SubscriptionInactiveException implements Exception {
  final String message;
  SubscriptionInactiveException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    bool auth = false,
  }) async {
    return _request("POST", path, body: body, auth: auth);
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
  }) async {
    return _request("GET", path, auth: auth);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
    Map<String, dynamic>? body,
  }) async {
    return _request("DELETE", path, body: body, auth: auth);
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}$path");
    final hasBody = body != null;
    final headers = await _headers(auth: auth, hasBody: hasBody);

    http.Response response;
    try {
      response = await _send(method, uri, headers, body).timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw Exception("Tempo esgotado. Verifique sua conexão.");
    } catch (_) {
      throw Exception("Falha de conexão com o servidor.");
    }

    if (response.statusCode == 401 && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final newHeaders = await _headers(auth: true, hasBody: hasBody);
        try {
          response = await _send(method, uri, newHeaders, body).timeout(ApiConfig.timeout);
        } on TimeoutException {
          throw Exception("Tempo esgotado. Verifique sua conexão.");
        }
      }
    }
    return _handleResponse(response);
  }

  static Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final encodedBody = body != null ? jsonEncode(body) : null;
    switch (method) {
      case "POST":
        return http.post(uri, headers: headers, body: encodedBody);
      case "DELETE":
        return http.delete(uri, headers: headers, body: encodedBody);
      case "GET":
      default:
        return http.get(uri, headers: headers);
    }
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

      // Só limpa se for erro de autenticação real
      if (response.statusCode == 401 || response.statusCode == 403) {
        await TokenStorage.clear();
      }
    } catch (_) {
      // Erro de rede — NÃO limpa o token, usuário pode tentar de novo
    }
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
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
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

    // Códigos especiais do backend
    if (response.statusCode == 403 && message == "EMAIL_NOT_VERIFIED") {
      throw EmailNotVerifiedException("Verifique seu e-mail para continuar.");
    }
    if (response.statusCode == 402) {
      if (message == "TRIAL_EXPIRED") {
        throw TrialExpiredException("Seu período de trial terminou. Assine para continuar.");
      }
      if (message == "SUBSCRIPTION_INACTIVE") {
        throw SubscriptionInactiveException("Sua assinatura está inativa.");
      }
    }

    throw Exception(message);
  }
}
