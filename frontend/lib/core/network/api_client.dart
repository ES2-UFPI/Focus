import 'package:flutter/foundation.dart';

/// URL base da API. Configurável por ambiente sem alterar o código:
/// `flutter run --dart-define=FOCUS_API_BASE_URL=http://10.0.2.2:8000`
/// (ex.: `10.0.2.2` no emulador Android, IP da LAN em dispositivo real).
/// Sem a flag, mantém o padrão local.
const String kBaseUrl = String.fromEnvironment(
  'FOCUS_API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

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