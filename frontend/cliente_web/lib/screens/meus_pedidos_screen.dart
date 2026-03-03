import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../widgets/app_sidebar.dart';

class MeusPedidosScreen extends StatefulWidget {
  const MeusPedidosScreen({super.key});

  @override
  State<MeusPedidosScreen> createState() => _MeusPedidosScreenState();
}

class _MeusPedidosScreenState extends State<MeusPedidosScreen>
    with TickerProviderStateMixin {
  final PedidoService _pedidoService = PedidoService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Pedido> _pedidos = [];
  bool _carregando = true;
  String? _erro;

  // Statuses a EXCLUIR (finalizado)
  static const List<String> _statusExcluidos = ['finalizado'];

  // Paleta de cores por status
  static const Map<String, _StatusStyle> _statusStyles = {
    'por finalizar': _StatusStyle(
      cor: Color(0xFFE67E22),
      corFundo: Color(0xFFFFF3E0),
      icone: Icons.pending_outlined,
      rotulo: 'Por Finalizar',
    ),
    'pendente': _StatusStyle(
      cor: Color(0xFF3498DB),
      corFundo: Color(0xFFE3F2FD),
      icone: Icons.hourglass_empty_rounded,
      rotulo: 'Pendente',
    ),
    'em preparacao': _StatusStyle(
      cor: Color(0xFF8E44AD),
      corFundo: Color(0xFFF3E5F5),
      icone: Icons.restaurant_menu_rounded,
      rotulo: 'Em Preparação',
    ),
    'pronto': _StatusStyle(
      cor: Color(0xFF27AE60),
      corFundo: Color(0xFFE8F5E9),
      icone: Icons.check_circle_outline_rounded,
      rotulo: 'Pronto',
    ),
    'a caminho': _StatusStyle(
      cor: Color(0xFF16A085),
      corFundo: Color(0xFFE0F2F1),
      icone: Icons.delivery_dining_rounded,
      rotulo: 'A Caminho',
    ),
    'cancelado': _StatusStyle(
      cor: Color(0xFFE74C3C),
      corFundo: Color(0xFFFFEBEE),
      icone: Icons.cancel_outlined,
      rotulo: 'Cancelado',
    ),
  };

  @override
  void initState() {
    super.initState();
    _carregarPedidos();
  }

  Future<void> _carregarPedidos() async {
    final usuario = SessaoService.instance.usuarioAtual;
    if (usuario == null) {
      setState(() {
        _erro = 'Utilizador não autenticado';
        _carregando = false;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final todos = await _pedidoService.listarPorUsuario(usuario.idUsuario);

      // Filtra pedidos finalizados
      final filtrados = todos
          .where((p) => !_statusExcluidos.contains(p.statusPedido))
          .toList();

      setState(() {
        _pedidos = filtrados;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar pedidos. Tente novamente.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppSidebar(currentRoute: '/meus_pedidos'),
      backgroundColor: const Color(0xFFF7F5F2),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: _buildConteudo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5F2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    size: 20,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _carregarPedidos,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Os Meus',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              letterSpacing: 2.5,
              color: Color(0xFF8A8A9A),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Pedidos',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 36,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          if (!_carregando && _pedidos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_pedidos.length} pedido${_pedidos.length != 1 ? 's' : ''} activo${_pedidos.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8A8A9A),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) return _buildCarregando();
    if (_erro != null) return _buildErro();
    if (_pedidos.isEmpty) return _buildVazio();
    return _buildLista();
  }

  Widget _buildCarregando() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF1A1A2E).withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'A carregar pedidos...',
            style: TextStyle(
              color: Color(0xFF8A8A9A),
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: Color(0xFFE74C3C),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1A2E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _carregarPedidos,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 44,
                color: Color(0xFFB0B0C0),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sem pedidos activos',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Os seus pedidos em curso\naparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A8A9A),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    return RefreshIndicator(
      onRefresh: _carregarPedidos,
      color: const Color(0xFF1A1A2E),
      strokeWidth: 2,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        itemCount: _pedidos.length,
        itemBuilder: (context, index) {
          return _PedidoCard(
            pedido: _pedidos[index],
            statusStyle: _statusStyles[_pedidos[index].statusPedido] ??
                const _StatusStyle(
                  cor: Color(0xFF8A8A9A),
                  corFundo: Color(0xFFF0F0F0),
                  icone: Icons.info_outline_rounded,
                  rotulo: 'Desconhecido',
                ),
            animationDelay: Duration(milliseconds: 60 * index),
          );
        },
      ),
    );
  }
}

// ─── Card de Pedido ────────────────────────────────────────────────────────────

class _PedidoCard extends StatefulWidget {
  final Pedido pedido;
  final _StatusStyle statusStyle;
  final Duration animationDelay;

  const _PedidoCard({
    required this.pedido,
    required this.statusStyle,
    required this.animationDelay,
  });

  @override
  State<_PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<_PedidoCard>
    with SingleTickerProviderStateMixin {
  bool _expandido = false;
  late AnimationController _controller;
  late Animation<double> _expansaoAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expansaoAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansao() {
    setState(() => _expandido = !_expandido);
    if (_expandido) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) return '—';
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${data.day.toString().padLeft(2, '0')} ${meses[data.month - 1]} · '
        '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  String _formatarMoeda(double valor) {
    return 'MZN ${valor.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final s = widget.statusStyle;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Cabeçalho do card ──────────────────────────────────────
            GestureDetector(
              onTap: _toggleExpansao,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Badge de status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: s.corFundo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(s.icone, size: 13, color: s.cor),
                              const SizedBox(width: 5),
                              Text(
                                s.rotulo,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: s.cor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Seta de expansão
                        AnimatedRotation(
                          turns: _expandido ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: Color(0xFF5A5A6A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.reference ?? 'Pedido #${p.idPedido}',
                                style: const TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatarData(p.dataPedido),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8A9A),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatarMoeda(p.total),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.totalItens} item${p.totalItens != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF8A8A9A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Separador com linha pontilhada ─────────────────────────
            if (_expandido || _controller.value > 0)
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: List.generate(
                      40,
                      (i) => Expanded(
                        child: Container(
                          height: 1,
                          color: i.isEven
                              ? const Color(0xFFEAEAEA)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Itens expandidos ───────────────────────────────────────
            SizeTransition(
              sizeFactor: _expansaoAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ITENS DO PEDIDO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A8A9A),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...p.itens.map((item) => _ItemRow(item: item)),
                      const SizedBox(height: 14),

                      // ── Total ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F5F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatarMoeda(p.total),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Info de entrega (se houver) ──────────────────
                      if (p.bairro != null || p.pontoReferencia != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icone: Icons.location_on_outlined,
                          label: 'Entrega',
                          valor: [
                            if (p.bairro != null) p.bairro!,
                            if (p.pontoReferencia != null) p.pontoReferencia!,
                          ].join(' · '),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Linha de Item ─────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final ItemPedido item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Quantidade badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.quantidade}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nome do produto
          Expanded(
            child: Text(
              item.nomeProduto,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF2C2C3E),
                height: 1.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          // Subtotal
          Text(
            'MZN ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Linha de Info ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;

  const _InfoRow({
    required this.icone,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 15, color: const Color(0xFF8A8A9A)),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, height: 1.4),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Color(0xFF8A8A9A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: valor,
                  style: const TextStyle(color: Color(0xFF2C2C3E)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data class imutável para estilos de status ───────────────────────────────

class _StatusStyle {
  final Color cor;
  final Color corFundo;
  final IconData icone;
  final String rotulo;

  const _StatusStyle({
    required this.cor,
    required this.corFundo,
    required this.icone,
    required this.rotulo,
  });
}