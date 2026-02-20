// lib/services/usuario_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuario_model.dart';

class UsuarioService {
  static const String _baseUrl = 'http://localhost:8080/api/usuarios';

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// POST /api/usuarios — cria funcionário com senha padrão
  /// O hash BCrypt é feito pelo Spring Boot
  Future<UsuarioModel> criarUsuario({
    required String nome,
    required String apelido,
    required String email,
    String? telefone,
    int idPerfil = 3,
  }) async {
    final body = jsonEncode({
      'nome': nome,
      'apelido': apelido,
      'email': email,
      'senha': '12345678',   // Spring Boot faz o hash
      'telefone': telefone,
      'idPerfil': idPerfil,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 201) {
      return UsuarioModel.fromJson(jsonDecode(response.body));
    }

    // Extrai mensagem de erro do backend quando disponível
    String erro = 'Erro ao cadastrar usuário (${response.statusCode})';
    try {
      final json = jsonDecode(response.body);
      erro = json['message'] ?? json['error'] ?? erro;
    } catch (_) {}

    throw Exception(erro);
  }

  /// GET /api/usuarios — listagem com filtros opcionais
  Future<List<UsuarioModel>> listarUsuarios({int? perfil, int? ativo}) async {
    final params = <String, String>{};
    if (perfil != null) params['perfil'] = '$perfil';
    if (ativo != null) params['ativo'] = '$ativo';

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => UsuarioModel.fromJson(e)).toList();
    }
    throw Exception('Erro ao listar usuários (${response.statusCode})');
  }

  /// GET /api/usuarios/{id}
  Future<UsuarioModel> buscarPorId(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/$id'), headers: _headers);

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Usuário não encontrado (${response.statusCode})');
  }

  /// PATCH /api/usuarios/{id}/toggle-status
  Future<UsuarioModel> toggleStatus(int id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/toggle-status'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao alterar status (${response.statusCode})');
  }

  /// PATCH /api/usuarios/{id}/reset-password
  Future<UsuarioModel> resetarSenha(int id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/reset-password'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao resetar senha (${response.statusCode})');
  }
}