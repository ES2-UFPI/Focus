import 'package:flutter/foundation.dart';

const String kBaseUrl = 'http://localhost:8000'; // Ajuste conforme sua URL base

class ApiClient {
  // 🔑 Armazenamento global do token dentro do core de rede
  static String? _token;

  /// Salva o token na memória global assim que o login for bem-sucedido
  static void setToken(String? token) {
    _token = token;
    if (kDebugMode) {
      print('🔑 [ApiClient] Token atualizado globalmente: $_token');
    }
  }

  /// Limpa o token no logout
  static void clearToken() {
    _token = null;
  }

  /// Getter dinâmico que substitui a constante antiga antiga
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };
}

// 🔄 Para manter a compatibilidade com o resto do seu projeto sem quebrar nada:
Map<String, String> get kDefaultHeaders => ApiClient.headers;