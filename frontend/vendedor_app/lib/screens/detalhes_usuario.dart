// lib/screens/detalhes_usuario.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetalhesUsuarioScreen extends StatefulWidget {
  final int usuarioId;
  const DetalhesUsuarioScreen({required this.usuarioId, super.key});

  @override
  State<DetalhesUsuarioScreen> createState() => _DetalhesUsuarioScreenState();
}

class _DetalhesUsuarioScreenState extends State<DetalhesUsuarioScreen> {
  static const String baseUrl = 'http://localhost:8080/api/usuarios';
  
  late Future<Usuario?> _usuarioFuture;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  void _loadUsuario() {
    setState(() {
      _usuarioFuture = _buscarUsuario();
    });
  }

  /// Busca usuário por ID na API
  Future<Usuario?> _buscarUsuario() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${widget.usuarioId}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Usuario.fromJson(jsonData);
      } else {
        throw Exception('Erro ao buscar usuário: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Alterna status (ativo/inativo) do usuário
  Future<void> _toggleAfastamento(Usuario usuario) async {
    final bool isAtivo = usuario.ativo == 1;
    final String acao = isAtivo ? 'Afastar' : 'Reativar';
    final String status = isAtivo ? 'Inativo' : 'Ativo';

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$acao Funcionário'),
        content: Text(
          'Tem certeza que deseja $acao ${usuario.nome}? '
          'O status dele mudará para "$status".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAtivo ? Colors.red : Colors.green,
            ),
            child: Text(acao),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/${widget.usuarioId}/toggle-status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _loadUsuario();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${usuario.nome} foi marcado como $status.')),
          );
        }
      } else {
        throw Exception('Erro ao alterar status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  /// Reinicia senha do usuário para padrão (12345678)
  Future<void> _reiniciarSenha(Usuario usuario) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Colors.orange),
            SizedBox(width: 10),
            Text('Reiniciar Senha'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja reiniciar a senha de ${usuario.nome}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Atenção:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• A senha será redefinida para: 12345678'),
                  Text('• O usuário será obrigado a criar uma nova senha no próximo login'),
                  Text('• Esta ação não pode ser desfeita'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reiniciar Senha'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    // Mostrar loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/${widget.usuarioId}/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading
      }

      if (response.statusCode == 200) {
        _loadUsuario();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Senha de ${usuario.nome} reiniciada com sucesso!\n'
                'Nova senha: 12345678',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        throw Exception('Erro ao resetar senha: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading se ainda estiver aberto
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao reiniciar senha: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPerfilName(int idPerfil) {
    switch (idPerfil) {
      case 1: return 'Administrador';
      case 2: return 'Gerente';
      case 3: return 'Funcionário';
      default: return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Usuário'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<Usuario?>(
        future: _usuarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Erro ao carregar usuário'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadUsuario,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Usuário não encontrado.'),
            );
          }

          final usuario = snapshot.data!;
          final isAtivo = usuario.ativo == 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. DADOS PESSOAIS
                Card(
                  elevation: 4,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAtivo ? Colors.green : Colors.grey,
                      child: Text(
                        usuario.nome[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    title: Text(
                      '${usuario.nome} ${usuario.apelido}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_getPerfilName(usuario.idPerfil)),
                    trailing: Icon(
                      isAtivo ? Icons.check_circle : Icons.person_off,
                      color: isAtivo ? Colors.green : Colors.red,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. DETALHES DE CONTATO
                const Text(
                  'Detalhes de Contato:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: const Text('Email'),
                  subtitle: Text(usuario.email),
                ),
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('Telefone'),
                  subtitle: Text(usuario.telefone ?? 'Não fornecido'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.orange),
                  title: const Text('Data de Cadastro'),
                  subtitle: Text(
                    '${usuario.dataCadastro.day.toString().padLeft(2, '0')}/'
                    '${usuario.dataCadastro.month.toString().padLeft(2, '0')}/'
                    '${usuario.dataCadastro.year} às '
                    '${usuario.dataCadastro.hour.toString().padLeft(2, '0')}:'
                    '${usuario.dataCadastro.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                
                // 3. AÇÕES DE GERENCIAMENTO
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Ações de Gerenciamento:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Botão Reiniciar Senha
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _reiniciarSenha(usuario),
                    icon: const Icon(Icons.lock_reset, color: Colors.white),
                    label: const Text(
                      'REINICIAR SENHA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botão Afastar/Reativar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleAfastamento(usuario),
                    icon: Icon(
                      isAtivo ? Icons.person_off : Icons.person_add,
                      color: Colors.white,
                    ),
                    label: Text(
                      isAtivo ? 'AFASTAR / DESLIGAR FUNCIONÁRIO' : 'REATIVAR FUNCIONÁRIO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAtivo ? Colors.red.shade700 : Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Informação sobre reinício de senha
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ao reiniciar a senha, o usuário receberá a senha padrão (12345678) e '
                          'será obrigado a criar uma nova senha no próximo login.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Classe Usuario (mesma da tela de listagem)
class Usuario {
  final int idUsuario;
  final String nome;
  final String apelido;
  final String email;
  final String? telefone;
  final int ativo;
  final String statusDescricao;
  final DateTime dataCadastro;
  final int? idProvincia;
  final int? idCidade;
  final int idPerfil;
  final int primeiraSenha;

  Usuario({
    required this.idUsuario,
    required this.nome,
    required this.apelido,
    required this.email,
    this.telefone,
    required this.ativo,
    required this.statusDescricao,
    required this.dataCadastro,
    this.idProvincia,
    this.idCidade,
    required this.idPerfil,
    required this.primeiraSenha,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['idUsuario'],
      nome: json['nome'],
      apelido: json['apelido'],
      email: json['email'],
      telefone: json['telefone'],
      ativo: json['ativo'],
      statusDescricao: json['statusDescricao'],
      dataCadastro: DateTime.parse(json['dataCadastro']),
      idProvincia: json['idProvincia'],
      idCidade: json['idCidade'],
      idPerfil: json['idPerfil'],
      primeiraSenha: json['primeiraSenha'],
    );
  }
}