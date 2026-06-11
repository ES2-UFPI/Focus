/// Configuração centralizada de rede para comunicação com o backend Django.
library;

const String kBaseUrl = 'http://localhost:8000';

String? _kAuthToken;

void setAuthToken(String? token) {
  _kAuthToken = token;
}

Map<String, String> get defaultHeaders => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  if (_kAuthToken != null) 'Authorization': 'Token $_kAuthToken',
};

// Mantido para compatibilidade com código legado que não precisa de auth.
const Map<String, String> kDefaultHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};
