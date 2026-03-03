import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_compartilhado/api_compartilhado.dart';import '../widgets/app_sidebar.dart';

class HistoricoPedidosScreen extends StatefulWidget {
  const HistoricoPedidosScreen({super.key});

  @override
  State<HistoricoPedidosScreen> createState() => _HistoricoPedidosScreenState();
}

class _HistoricoPedidosScreenState extends State<HistoricoPedidosScreen>
    with TickerProviderStateMixin {
  final PedidoService _pedidoService = PedidoService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Pedido> _pedidos = [];
  bool _carregando = true;
  String? _erro;

  // Totais calculados
  double get _totalGasto =>
      _pedidos.fold(0.0, (soma, p) => soma + p.total);

  int get _totalItensComprados =>
      _pedidos.fold(0, (soma, p) => soma + p.totalItens);

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
      // Usa o endpoint específico de status para maior eficiência
      final finalizados = await _pedidoService.listarPorStatusEUsuario(
        'finalizado',
        usuario.idUsuario,
      );

      setState(() {
        _pedidos = finalizados;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar o histórico. Tente novamente.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppSidebar(currentRoute: '/historico_pedidos'),
      backgroundColor: const Color(0xFF12121C),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (!_carregando && _erro == null && _pedidos.isNotEmpty)
                _buildSummaryBar(),
              Expanded(child: _buildConteudo()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Botão menu (drawer)
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // Botão refresh
              GestureDetector(
                onTap: _carregarPedidos,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Ícone de histórico
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 24,
              color: Color(0xFF2ECC71),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'HISTÓRICO',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 3.5,
              color: Color(0xFF2ECC71),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pedidos\nFinalizados',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // ── Barra de resumo ────────────────────────────────────────────────────────

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _SummaryTile(
            label: 'Pedidos',
            valor: '${_pedidos.length}',
            icone: Icons.receipt_long_outlined,
          ),
          _buildDivider(),
          _SummaryTile(
            label: 'Itens',
            valor: '$_totalItensComprados',
            icone: Icons.shopping_bag_outlined,
          ),
          _buildDivider(),
          _SummaryTile(
            label: 'Total gasto',
            valor: 'MZN ${_totalGasto.toStringAsFixed(0)}',
            icone: Icons.payments_outlined,
            destaque: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withOpacity(0.1),
    );
  }

  // ── Conteúdo principal ─────────────────────────────────────────────────────

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
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF2ECC71).withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'A carregar histórico...',
            style: TextStyle(
              color: Color(0xFF6B6B80),
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
                color: Colors.red.withOpacity(0.12),
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
                color: Colors.white,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _carregarPedidos,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(
                    color: Color(0xFF12121C),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 44,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sem histórico',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Os pedidos finalizados\naparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.4),
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
      color: const Color(0xFF2ECC71),
      backgroundColor: const Color(0xFF1E1E2E),
      strokeWidth: 2,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        itemCount: _pedidos.length,
        itemBuilder: (context, index) {
          return _PedidoFinalizadoCard(
            pedido: _pedidos[index],
            animationDelay: Duration(milliseconds: 50 * index),
          );
        },
      ),
    );
  }
}

// ─── Card de Pedido Finalizado ────────────────────────────────────────────────

class _PedidoFinalizadoCard extends StatefulWidget {
  final Pedido pedido;
  final Duration animationDelay;

  const _PedidoFinalizadoCard({
    required this.pedido,
    required this.animationDelay,
  });

  @override
  State<_PedidoFinalizadoCard> createState() => _PedidoFinalizadoCardState();
}

class _PedidoFinalizadoCardState extends State<_PedidoFinalizadoCard>
    with SingleTickerProviderStateMixin {
  bool _expandido = false;
  late AnimationController _controller;
  late Animation<double> _expansaoAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _expansaoAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansao() {
    setState(() => _expandido = !_expandido);
    _expandido ? _controller.forward() : _controller.reverse();
  }

  String _formatarData(DateTime? data) {
    if (data == null) return '—';
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return '${data.day.toString().padLeft(2, '0')} ${meses[data.month - 1]} ${data.year} · '
        '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  String _formatarMoeda(double valor) =>
      'MZN ${valor.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Linha de destaque verde no topo ──────────────────────────
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2ECC71), Color(0xFF1ABC9C)],
                ),
              ),
            ),

            // ── Cabeçalho do card ─────────────────────────────────────
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
                        // Badge "Finalizado"
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2ECC71).withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: Color(0xFF2ECC71),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Finalizado',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2ECC71),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Seta expansão
                        AnimatedRotation(
                          turns: _expandido ? 0.5 : 0,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeInOutCubic,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatarData(p.dataPedido),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.4),
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
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${p.totalItens} item${p.totalItens != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withOpacity(0.35),
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

            // ── Separador pontilhado ──────────────────────────────────
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
                              ? Colors.white.withOpacity(0.08)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Itens expandidos ──────────────────────────────────────
            SizeTransition(
              sizeFactor: _expansaoAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ITENS DO PEDIDO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.35),
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lista de itens
                      ...p.itens.map((item) => _ItemRow(item: item)),

                      const SizedBox(height: 16),

                      // ── Bloco de resumo financeiro ──────────────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _ResumoRow(
                              label: 'Subtotal',
                              valor: _formatarMoeda(p.total),
                              destaque: false,
                            ),
                            if (p.troco > 0) ...[
                              const SizedBox(height: 8),
                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.07),
                              ),
                              const SizedBox(height: 8),
                              _ResumoRow(
                                label: 'Valor pago',
                                valor: _formatarMoeda(p.valorPagoManual),
                                destaque: false,
                              ),
                              const SizedBox(height: 6),
                              _ResumoRow(
                                label: 'Troco',
                                valor: _formatarMoeda(p.troco),
                                destaque: false,
                                corValor: const Color(0xFF2ECC71),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.07),
                            ),
                            const SizedBox(height: 8),
                            _ResumoRow(
                              label: 'TOTAL',
                              valor: _formatarMoeda(p.total),
                              destaque: true,
                            ),
                          ],
                        ),
                      ),

                      // ── Dados extras: entrega e cliente ────────────
                      if (p.nomeCliente != null ||
                          p.apelidoCliente != null ||
                          p.bairro != null ||
                          p.pontoReferencia != null ||
                          p.telefone != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DETALHES',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (p.nomeCliente != null ||
                                  p.apelidoCliente != null)
                                _InfoRow(
                                  icone: Icons.person_outline_rounded,
                                  label: 'Cliente',
                                  valor: [
                                    if (p.nomeCliente != null) p.nomeCliente!,
                                    if (p.apelidoCliente != null)
                                      p.apelidoCliente!,
                                  ].join(' '),
                                ),
                              if (p.telefone != null) ...[
                                const SizedBox(height: 6),
                                _InfoRow(
                                  icone: Icons.phone_outlined,
                                  label: 'Telefone',
                                  valor: p.telefone!,
                                ),
                              ],
                              if (p.bairro != null ||
                                  p.pontoReferencia != null) ...[
                                const SizedBox(height: 6),
                                _InfoRow(
                                  icone: Icons.location_on_outlined,
                                  label: 'Entrega',
                                  valor: [
                                    if (p.bairro != null) p.bairro!,
                                    if (p.pontoReferencia != null)
                                      p.pontoReferencia!,
                                  ].join(' · '),
                                ),
                              ],
                            ],
                          ),
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

// ─── Linha de Item ────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final ItemPedido item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Badge quantidade
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.quantidade}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nome do produto
          Expanded(
            child: Text(
              item.nomeProduto,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withOpacity(0.8),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Linha de Resumo Financeiro ───────────────────────────────────────────────

class _ResumoRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;
  final Color? corValor;

  const _ResumoRow({
    required this.label,
    required this.valor,
    required this.destaque,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: destaque ? 13 : 12.5,
            fontWeight: destaque ? FontWeight.w700 : FontWeight.w400,
            color: destaque
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            letterSpacing: destaque ? 0.5 : 0,
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
            color: corValor ??
                (destaque ? Colors.white : Colors.white.withOpacity(0.7)),
          ),
        ),
      ],
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
        Icon(icone, size: 14, color: Colors.white.withOpacity(0.35)),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, height: 1.4),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: valor,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tile de Resumo (barra de stats) ─────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icone;
  final bool destaque;

  const _SummaryTile({
    required this.label,
    required this.valor,
    required this.icone,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icone,
            size: 15,
            color: destaque
                ? const Color(0xFF2ECC71)
                : Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: destaque ? 13 : 14,
              fontWeight: FontWeight.w800,
              color: destaque ? const Color(0xFF2ECC71) : Colors.white,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}