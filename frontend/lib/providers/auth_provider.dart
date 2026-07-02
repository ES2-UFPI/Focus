import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _logado = false;
  Map<String, dynamic>? _aluno;

  bool get logado => _logado;
  Map<String, dynamic>? get aluno => _aluno;
  String get nomeAluno => _aluno?['nome'] ?? '';
  String get emailAluno => _aluno?['email'] ?? '';

  final ApiService apiService;

  AuthProvider(this.apiService);

  Future<void> init() async {
    final token = await AuthService.getToken();
    if (token != null) {
      _aluno = await AuthService.getAluno();
      apiService.setToken(token);
      atualizarTokenNoCore(token); // 👈 Mudou aqui
      _logado = true;
    }
  }

  Future<String?> login(String email, String senha) async {
    final result = await AuthService.login(email, senha);
    if (result['sucesso'] == true) {
      _aluno = result['aluno'];
      final token = await AuthService.getToken();
      apiService.setToken(token!);
      atualizarTokenNoCore(token); // 👈 Mudou aqui
      _logado = true;
      notifyListeners();
      return null;
    }
    return result['erro'] as String;
  }

  Future<String?> registro({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final result = await AuthService.registro(nome: nome, email: email, senha: senha);
    if (result['sucesso'] == true) {
      _aluno = result['aluno'];
      final token = await AuthService.getToken();
      apiService.setToken(token!);
      atualizarTokenNoCore(token); // 👈 Mudou aqui
      _logado = true;
      notifyListeners();
      return null;
    }
    return result['erro'] as String;
  }

  Future<void> logout() async {
    await AuthService.logout();
    apiService.clearToken();
    atualizarTokenNoCore(null); // 👈 Mudou aqui
    _aluno = null;
    _logado = false;
    notifyListeners();
  }

  // ===========================================================================
  // 🛠️ MÉTODO ADICIONADO: Sincroniza o Token com o Core de Rede (Opção A)
  // ===========================================================================
  // 🔑 Nome único para evitar conflitos de importação
  void atualizarTokenNoCore(String? token) {
    ApiClient.setToken(token);
  }
}