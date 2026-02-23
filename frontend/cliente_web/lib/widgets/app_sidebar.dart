

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:api_compartilhado/api_compartilhado.dart';

// TODO: Descomentar quando servico_logs for migrado para Spring Boot
// import '../services/servico_logs.dart';

// TODO: Descomentar quando estoque_badge for migrado/validado
import '../widgets/estoque_badge.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute;

  const AppSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  bool _showUserMenu = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  // TODO: Reactivar quando pedido_contador_service estiver migrado
  int _contadorPedidos = 0;
  StreamSubscription<int>? _contadorSubscription;
  final PedidoContadorService _contadorService = PedidoContadorService.instance;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    EstoqueAlertaService.instance.inicializar();
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // TODO: Reactivar quando pedido_contador_service estiver migrado
    _carregarContadorDoUsuario();
    _contadorPedidos = _contadorService.contadorAtual;
    _contadorSubscription = _contadorService.contadorStream.listen((novoValor) {
      if (mounted) {
        setState(() {
          _contadorPedidos = novoValor;
        });
      }
    });
  }

  // TODO: Reactivar quando pedido_contador_service estiver migrado
  Future<void> _carregarContadorDoUsuario() async {
    final usuario = SessaoService.instance.usuarioAtual;
    if (usuario != null) {
      await _contadorService.recarregarSeNecessario();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();

    // TODO: Reactivar quando pedido_contador_service estiver migrado
    _contadorSubscription?.cancel();

    super.dispose();
  }

  void _toggleUserMenu() {
    setState(() {
      _showUserMenu = !_showUserMenu;
      if (_showUserMenu) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  /// Verifica se o utilizador logado tem permissão para aceder à rota
  bool _temPermissao(String route) {
    final usuario = SessaoService.instance.usuarioAtual;
    if (usuario == null) return false;

    // 🔥 ADAPTAÇÃO: idPerfil não-nullable em UsuarioModel
    final idPerfil = usuario.idPerfil;

    // Administrador tem acesso a tudo
    if (idPerfil == 1) return true;

    // Gerente
    if (idPerfil == 2) {
      return [
        '/dashboard',
        '/menu',
        '/categorias',
         '/marcas',
        '/produtos',
        '/movimentos_estoque',
        // '/historico_pedidos',
      ].contains(route);
    }

    // Funcionário
    if (idPerfil == 3) {
      return [
        '/menu',
        '/dashboard',
      ].contains(route);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = SessaoService.instance.usuarioAtual;

    if (usuario == null) {
      return const SizedBox.shrink();
    }

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(usuario),

                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/dashboard',
                ),

                // Criar Pedido
                // TODO: Substituir _buildMenuItem por _buildMenuItemComContador
                //       quando pedido_contador_service estiver migrado:
                //
                if (_temPermissao('/menu'))
                  _buildMenuItemComContador(
                    icon: Icons.shopping_cart,
                    title: 'Criar Pedido',
                    route: '/menu',
                    contador: _contadorPedidos,
                  ),
                // if (_temPermissao('/menu'))
                //   _buildMenuItem(
                //     icon: Icons.shopping_cart,
                //     title: 'Criar Pedido',
                //     route: '/menu',
                //   ),

                if (_temPermissao('/categorias'))
                  _buildMenuItem(
                    icon: Icons.category,
                    title: 'Gerenciar Categorias',
                    route: '/categorias',
                  ),

                     if (_temPermissao('/marcas'))
                  _buildMenuItem(
                    icon: Icons.shopping_cart,
                    title: 'Gerenciar Marcas',
                    route: '/marcas',
                  ),

                // Gerenciar Produtos
                // TODO: Reactivar usarBadge: true quando estoque_badge estiver validado
             if (_temPermissao('/produtos'))
  _buildMenuItem(
    icon: Icons.fastfood,
    title: 'Gerenciar Produtos',
    route: '/produtos',
    usarBadge: true,
  ),

                if (_temPermissao('/gerenciar_usuarios'))
                  _buildMenuItem(
                    icon: Icons.people,
                    title: 'Gerenciar Usuários',
                    route: '/gerenciar_usuarios',
                  ),

                // if (_temPermissao('/historico_pedidos'))
                //   _buildMenuItem(
                //     icon: Icons.history,
                //     title: 'Histórico de Pedidos',
                //     route: '/historico_pedidos',
                //   ),

                // if (_temPermissao('/logs'))
                //   _buildMenuItem(
                //     icon: Icons.list_alt,
                //     title: 'Logs do Sistema',
                //     route: '/logs',
                //   ),

                if (_temPermissao('/movimentos_estoque'))
                  _buildMenuItem(
                    icon: Icons.inventory,
                    title: 'Movimentos de Estoque',
                    route: '/movimentos_estoque',
                  ),
              ],
            ),
          ),

          _buildUserSection(usuario),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(usuario) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepOrange, Colors.deepOrange.shade700],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            // 🔥 ADAPTAÇÃO: idUsuario em vez de id
            tag: 'user_avatar_${usuario.idUsuario}',
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Text(
                // 🔥 ADAPTAÇÃO: nome não-nullable — sem !
                usuario.nome[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${usuario.nome} ${usuario.apelido}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getPerfilName(usuario.idPerfil),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
    // TODO: Reactivar quando estoque_badge estiver validado
    bool usarBadge = false,
  }) {
    final isSelected = widget.currentRoute == route;

    Widget iconWidget = Icon(
      icon,
      color: isSelected ? Colors.deepOrange : Colors.grey[700],
    );

    // TODO: Reactivar quando estoque_badge estiver validado
    if (usarBadge) {
      iconWidget = EstoqueBadge(child: iconWidget);
    }

    return ListTile(
      leading: iconWidget,
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.deepOrange : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.deepOrange.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  // TODO: Reactivar este método completo quando pedido_contador_service
  //       estiver migrado para Spring Boot
  //
  Widget _buildMenuItemComContador({
    required IconData icon,
    required String title,
    required String route,
    required int contador,
  }) {
    final isSelected = widget.currentRoute == route;
  
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.deepOrange : Colors.grey[700],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.deepOrange : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (contador > 0)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '$contador',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: Colors.deepOrange.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildUserSection(usuario) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomCenter,
            child: _showUserMenu
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildUserMenuItem(
                          icon: Icons.person,
                          title: 'Alterar Dados',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/editar_usuario');
                          },
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildUserMenuItem(
                          icon: Icons.lock,
                          title: 'Alterar Senha',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/alterar_senha');
                          },
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildUserMenuItem(
                          icon: Icons.logout,
                          title: 'Sair',
                          color: Colors.red,
                          onTap: () => _confirmarLogout(context),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleUserMenu,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.deepOrange,
                      child: Text(
                        usuario.nome[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${usuario.nome} ${usuario.apelido}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            // 🔥 ADAPTAÇÃO: email não-nullable em UsuarioModel
                            usuario.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(Icons.expand_less, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: title == 'Sair' ? Colors.red : Colors.black87,
          fontSize: 14,
        ),
      ),
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  Future<void> _confirmarLogout(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirmar Saída'),
          ],
        ),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      // TODO: Reactivar log de logout quando servico_logs estiver migrado
      // final usuario = SessaoService.instance.usuarioAtual;
      // if (usuario != null) {
      //   await ServicoLogs.instance.registrarLogout(
      //     usuario.idUsuario,
      //     '${usuario.nome} ${usuario.apelido}',
      //   );
      // }

      // TODO: Reactivar quando pedido_contador_service estiver migrado
      _contadorService.resetar();

      SessaoService.instance.limparSessao();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
      case 4:
        return 'Cliente';
      default:
        return 'Usuário';
    }
  }
}