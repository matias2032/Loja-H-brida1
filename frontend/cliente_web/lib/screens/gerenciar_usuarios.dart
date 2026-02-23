// lib/screens/gerenciar_usuarios.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_sidebar.dart';
// import '../widgets/theme_toggle_widget.dart';
// import '../widgets/conectividade_indicator.dart';

enum StatusFiltro {
  todos,
  ativo,
  inativo,
}

enum PerfilFiltro {
  todos,
  gerente,
  funcionario,
}

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

class UsuarioListScreen extends StatefulWidget {
  const UsuarioListScreen({super.key});

  @override
  State<UsuarioListScreen> createState() => _UsuarioListScreenState();
}

class _UsuarioListScreenState extends State<UsuarioListScreen> {
  // 🔧 CONFIGURE SUA URL BASE AQUI
  static const String baseUrl = 'http://localhost:8080/api/usuarios';
  
  late Future<List<Usuario>> _usuariosFuture;
  StatusFiltro _statusFiltro = StatusFiltro.todos;
  PerfilFiltro _perfilFiltro = PerfilFiltro.todos;

  @override
  void initState() {
    super.initState();
    _usuariosFuture = _loadUsuarios();
  }

  /// Carrega usuários da API REST com filtros
  Future<List<Usuario>> _loadUsuarios() async {
    try {
      // Constrói URL com query parameters
      String url = baseUrl;
      List<String> queryParams = [];

      // Filtro de perfil
      if (_perfilFiltro == PerfilFiltro.gerente) {
        queryParams.add('perfil=2');
      } else if (_perfilFiltro == PerfilFiltro.funcionario) {
        queryParams.add('perfil=3');
      }

      // Filtro de status
      if (_statusFiltro == StatusFiltro.ativo) {
        queryParams.add('ativo=1');
      } else if (_statusFiltro == StatusFiltro.inativo) {
        queryParams.add('ativo=0');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      // Faz requisição HTTP
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Usuario.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar usuários: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Alterna status (ativo/inativo) do usuário
  Future<void> _toggleStatus(int idUsuario) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$idUsuario/toggle-status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status alterado com sucesso!')),
        );
        setState(() {
          _usuariosFuture = _loadUsuarios();
        });
      } else {
        throw Exception('Erro ao alterar status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  /// Reseta senha do usuário para padrão (12345678)
  Future<void> _resetarSenha(int idUsuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar Senha'),
        content: const Text(
          'Tem certeza que deseja resetar a senha para 12345678?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$idUsuario/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha resetada com sucesso!')),
        );
        setState(() {
          _usuariosFuture = _loadUsuarios();
        });
      } else {
        throw Exception('Erro ao resetar senha: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  String _getPerfilName(int idPerfil) {
    switch (idPerfil) {
      case 1:
        return 'Administrador';
      case 2:
        return 'Gerente';
      case 3:
        return 'Funcionário';
      default:
        return 'Cliente';
    }
  }

  String _getFiltroLabel() {
    String status = '';
    switch (_statusFiltro) {
      case StatusFiltro.ativo:
        status = 'Ativos';
        break;
      case StatusFiltro.inativo:
        status = 'Inativos';
        break;
      case StatusFiltro.todos:
        status = 'Todos';
        break;
    }

    String perfil = '';
    switch (_perfilFiltro) {
      case PerfilFiltro.gerente:
        perfil = ' - Gerentes';
        break;
      case PerfilFiltro.funcionario:
        perfil = ' - Funcionários';
        break;
      case PerfilFiltro.todos:
        perfil = '';
        break;
    }

    return '$status$perfil';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuários (${_getFiltroLabel()})'),
        backgroundColor: Colors.deepOrange,
        actions: [
          // const ConectividadeIndicator(),
          // ThemeToggleWidget(showLabel: false),
          
          // Filtro de Status
          PopupMenuButton<StatusFiltro>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por Status',
            onSelected: (StatusFiltro newFilter) {
              setState(() {
                _statusFiltro = newFilter;
                _usuariosFuture = _loadUsuarios();
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: StatusFiltro.todos,
                child: Text('Todos os Status'),
              ),
              const PopupMenuItem(
                value: StatusFiltro.ativo,
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Apenas Ativos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: StatusFiltro.inativo,
                child: Row(
                  children: [
                    Icon(Icons.person_off, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Apenas Inativos'),
                  ],
                ),
              ),
            ],
          ),

          // Filtro de Perfil
          PopupMenuButton<PerfilFiltro>(
            icon: const Icon(Icons.group),
            tooltip: 'Filtrar por Perfil',
            onSelected: (PerfilFiltro newFilter) {
              setState(() {
                _perfilFiltro = newFilter;
                _usuariosFuture = _loadUsuarios();
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: PerfilFiltro.todos,
                child: Text('Todos os Perfis'),
              ),
              const PopupMenuItem(
                value: PerfilFiltro.gerente,
                child: Text('Apenas Gerentes'),
              ),
              const PopupMenuItem(
                value: PerfilFiltro.funcionario,
                child: Text('Apenas Funcionários'),
              ),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: () {
              setState(() {
                _usuariosFuture = _loadUsuarios();
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Novo Usuário',
            onPressed: () async {
              await Navigator.of(context).pushNamed('/cadastro_usuario');
              setState(() {
                _usuariosFuture = _loadUsuarios();
              });
            },
          ),
        ],
      ),


      drawer: const AppSidebar(currentRoute: '/gerenciar_usuarios'),
      
      body: FutureBuilder<List<Usuario>>(
        future: _usuariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar usuários',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _usuariosFuture = _loadUsuarios();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum usuário encontrado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(_getFiltroLabel()),
                ],
              ),
            );
          }

          final usuarios = snapshot.data!;

          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              final perfilNome = _getPerfilName(usuario.idPerfil);
              final isAtivo = usuario.ativo == 1;
              final statusColor = isAtivo ? Colors.green : Colors.red;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAtivo ? Colors.green : Colors.grey,
                    child: Text(
                      usuario.nome[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '${usuario.nome} ${usuario.apelido} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '($perfilNome)',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  subtitle: Text(
                    '${usuario.email}\nTel: ${usuario.telefone ?? 'N/A'}\n'
                    'Status: ${usuario.statusDescricao}',
                  ),
                  isThreeLine: true,

                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'toggle':
                          _toggleStatus(usuario.idUsuario);
                          break;
                        case 'reset':
                          _resetarSenha(usuario.idUsuario);
                          break;
                        case 'detalhes':
                          Navigator.pushNamed(
                            context,
                            '/detalhes_usuario',
                            arguments: usuario.idUsuario,
                          ).then((_) {
                            setState(() {
                              _usuariosFuture = _loadUsuarios();
                            });
                          });
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'detalhes',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text('Ver Detalhes'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isAtivo ? Icons.person_off : Icons.person,
                              color: isAtivo ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(isAtivo ? 'Desativar' : 'Ativar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.lock_reset, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Resetar Senha'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/detalhes_usuario',
                      arguments: usuario.idUsuario,
                    ).then((_) {
                      setState(() {
                        _usuariosFuture = _loadUsuarios();
                      });
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}