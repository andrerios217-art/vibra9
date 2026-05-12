class ApiConfig {
  // Para alternar entre dev e prod, mude este valor:
  static const bool isProduction = true;

  static const String _devUrl = "http://127.0.0.1:8001";
  static const String _prodUrl = "https://vibra9.onrender.com";

  static String get baseUrl => isProduction ? _prodUrl : _devUrl;
  static const Duration timeout = Duration(seconds: 30);
}
