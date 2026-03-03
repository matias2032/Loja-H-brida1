import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_compartilhado.dart';import '../widgets/app_sidebar.dart';

// ─── Extensão local do PedidoService para endpoint admin ─────────────────────
// GET /api/pedidos/status/{status}  →  todos os pedidos, todos os usuários
extension PedidoServiceAdmin on PedidoService {
  Future<List<Pedido>> listarTodosPorStatus(String status) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.pedidosUrl}/status/${Uri.encodeComponent(status)}',
            ),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => Pedido.fromJson(e)).toList();
      } else {
        throw Exception(
            'Erro ao listar pedidos finalizados: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro em listarTodosPorStatus: $e');
      rethrow;
    }
  }
}

// ─── Tela principal ───────────────────────────────────────────────────────────

class AdminPedidosFinalizadosScreen extends StatefulWidget {
  const AdminPedidosFinalizadosScreen({super.key});

  @override
  State<AdminPedidosFinalizadosScreen> createState() =>
      _AdminPedidosFinalizadosScreenState();
}

class _AdminPedidosFinalizadosScreenState
    extends State<AdminPedidosFinalizadosScreen>
    with SingleTickerProviderStateMixin {
  final PedidoService _pedidoService = PedidoService();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Pedido> _todos = [];
  List<Pedido> _filtrados = [];
  bool _carregando = true;
  String? _erro;

  // Filtros
  String _termoBusca = '';
  _OrdemFiltro _ordem = _OrdemFiltro.maisRecente;

  // ── Métricas calculadas ─────────────────────────────────────────────────
  double get _receita => _todos.fold(0.0, (s, p) => s + p.total);
  int get _totalItens => _todos.fold(0, (s, p) => s + p.totalItens);
  double get _ticketMedio => _todos.isEmpty ? 0 : _receita / _todos.length;

  // Nº de usuários únicos
  int get _clientesUnicos =>
      _todos.map((p) => p.idUsuario).toSet().length;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_aplicarFiltros);
    _carregarPedidos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Carregamento ────────────────────────────────────────────────────────

  Future<void> _carregarPedidos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _pedidoService.listarTodosPorStatus('finalizado');
      setState(() {
        _todos = lista;
        _carregando = false;
      });
      _aplicarFiltros();
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar os pedidos. Tente novamente.';
        _carregando = false;
      });
    }
  }

  // ── Filtros e ordenação ─────────────────────────────────────────────────

  void _aplicarFiltros() {
    final termo = _searchController.text.toLowerCase().trim();
    setState(() {
      _termoBusca = termo;
      var resultado = _todos.where((p) {
        if (termo.isEmpty) return true;
        final ref = (p.reference ?? '').toLowerCase();
        final nome =
            '${p.nomeCliente ?? ''} ${p.apelidoCliente ?? ''}'.toLowerCase();
        final tel = (p.telefone ?? '').toLowerCase();
        final id = '${p.idUsuario}'.toLowerCase();
        return ref.contains(termo) ||
            nome.contains(termo) ||
            tel.contains(termo) ||
            id.contains(termo);
      }).toList();

      resultado.sort((a, b) {
        switch (_ordem) {
          case _OrdemFiltro.maisRecente:
            return (b.dataPedido ?? DateTime(0))
                .compareTo(a.dataPedido ?? DateTime(0));
          case _OrdemFiltro.maisAntigo:
            return (a.dataPedido ?? DateTime(0))
                .compareTo(b.dataPedido ?? DateTime(0));
          case _OrdemFiltro.maiorValor:
            return b.total.compareTo(a.total);
          case _OrdemFiltro.menorValor:
            return a.total.compareTo(b.total);
        }
      });

      _filtrados = resultado;
    });
  }

  void _setOrdem(_OrdemFiltro nova) {
    setState(() => _ordem = nova);
    _aplicarFiltros();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppSidebar(currentRoute: '/admin_historico_pedidos'),
      backgroundColor: const Color(0xFF0F1117),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (!_carregando && _erro == null && _todos.isNotEmpty) ...[
                _buildMetricas(),
                _buildBuscaEFiltros(),
              ],
              Expanded(child: _buildConteudo()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: const Icon(Icons.menu_rounded,
                  size: 19, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0B429),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'PAINEL ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.8,
                      color: Color(0xFFF0B429),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Pedidos Finalizados',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _carregarPedidos,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: const Icon(Icons.refresh_rounded,
                  size: 19, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Métricas ────────────────────────────────────────────────────────────

  Widget _buildMetricas() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Linha 1: Receita total + Pedidos
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _MetricCard(
                  label: 'Receita Total',
                  valor: 'MZN ${_receita.toStringAsFixed(2)}',
                  icone: Icons.payments_rounded,
                  cor: const Color(0xFFF0B429),
                  grande: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _MetricCard(
                  label: 'Pedidos',
                  valor: '${_todos.length}',
                  icone: Icons.receipt_long_rounded,
                  cor: const Color(0xFF6C8EF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Linha 2: Ticket médio + Clientes + Itens
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Ticket Médio',
                  valor: 'MZN ${_ticketMedio.toStringAsFixed(0)}',
                  icone: Icons.trending_up_rounded,
                  cor: const Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Clientes',
                  valor: '$_clientesUnicos',
                  icone: Icons.people_outline_rounded,
                  cor: const Color(0xFFE67E22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Itens',
                  valor: '$_totalItens',
                  icone: Icons.shopping_bag_outlined,
                  cor: const Color(0xFFAB84F5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Barra de busca + filtros ─────────────────────────────────────────────

  Widget _buildBuscaEFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          // Campo de busca
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1E28),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded,
                    size: 18, color: Colors.white.withOpacity(0.35)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white, height: 1.0),
                    decoration: InputDecoration(
                      hintText:
                          'Pesquisar por referência, cliente ou telefone…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.25),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    cursorColor: const Color(0xFFF0B429),
                  ),
                ),
                if (_termoBusca.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.close_rounded,
                          size: 17, color: Colors.white.withOpacity(0.4)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Chips de ordenação
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _OrdemFiltro.values.map((o) {
                final activo = _ordem == o;
                return GestureDetector(
                  onTap: () => _setOrdem(o),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: activo
                          ? const Color(0xFFF0B429)
                          : const Color(0xFF1C1E28),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: activo
                            ? const Color(0xFFF0B429)
                            : Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      o.rotulo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: activo
                            ? const Color(0xFF0F1117)
                            : Colors.white.withOpacity(0.5),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Contador de resultados
          Row(
            children: [
              Text(
                _termoBusca.isEmpty
                    ? '${_filtrados.length} pedidos'
                    : '${_filtrados.length} resultado${_filtrados.length != 1 ? 's' : ''} para "$_termoBusca"',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Conteúdo ────────────────────────────────────────────────────────────

  Widget _buildConteudo() {
    if (_carregando) return _buildCarregando();
    if (_erro != null) return _buildErro();
    if (_todos.isEmpty) return _buildVazio();
    if (_filtrados.isEmpty) return _buildSemResultados();
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
                  const Color(0xFFF0B429).withOpacity(0.8)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A carregar pedidos…',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: 14),
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 30, color: Color(0xFFE74C3C)),
            ),
            const SizedBox(height: 18),
            Text(_erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.5)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: _carregarPedidos,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0B429),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Text('Tentar novamente',
                    style: TextStyle(
                        color: Color(0xFF0F1117),
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 52, color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 16),
          Text('Nenhum pedido finalizado',
              style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSemResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 14),
          Text('Sem resultados para\n"$_termoBusca"',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.4),
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return RefreshIndicator(
      onRefresh: _carregarPedidos,
      color: const Color(0xFFF0B429),
      backgroundColor: const Color(0xFF1C1E28),
      strokeWidth: 2,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        itemCount: _filtrados.length,
        itemBuilder: (context, index) =>
            _AdminPedidoCard(pedido: _filtrados[index]),
      ),
    );
  }
}

// ─── Card Admin ───────────────────────────────────────────────────────────────

class _AdminPedidoCard extends StatefulWidget {
  final Pedido pedido;

  const _AdminPedidoCard({required this.pedido});

  @override
  State<_AdminPedidoCard> createState() => _AdminPedidoCardState();
}

class _AdminPedidoCardState extends State<_AdminPedidoCard>
    with SingleTickerProviderStateMixin {
  bool _expandido = false;
  late AnimationController _ctrl;
  late Animation<double> _expansao;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _expansao =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _fade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expandido = !_expandido);
    _expandido ? _ctrl.forward() : _ctrl.reverse();
  }

  String _formatarData(DateTime? d) {
    if (d == null) return '—';
    final m = [
      'Jan','Fev','Mar','Abr','Mai','Jun',
      'Jul','Ago','Set','Out','Nov','Dez'
    ];
    return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]} ${d.year}  '
        '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  String _moeda(double v) => 'MZN ${v.toStringAsFixed(2)}';

  String get _nomeCliente {
    final n = widget.pedido.nomeCliente;
    final a = widget.pedido.apelidoCliente;
    if (n == null && a == null) return '—';
    return [if (n != null) n, if (a != null) a].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161820),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // ── Faixa dourada no topo ───────────────────────────────────
            Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF0B429), Color(0xFFFFD700)],
                ),
              ),
            ),

            // ── Cabeçalho ───────────────────────────────────────────────
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha 1: reference + seta
                    Row(
                      children: [
                        // ID do usuário badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6C8EF5).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: const Color(0xFF6C8EF5)
                                    .withOpacity(0.25),
                                width: 1),
                          ),
                          child: Text(
                            'ID Usuário: ${p.idUsuario}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6C8EF5),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badge finalizado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2ECC71).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: const Color(0xFF2ECC71)
                                    .withOpacity(0.2),
                                width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 11, color: Color(0xFF2ECC71)),
                              SizedBox(width: 4),
                              Text(
                                'Finalizado',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2ECC71),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _expandido ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 19,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Linha 2: reference + total
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Nome do cliente
                              Text(
                                _nomeCliente,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatarData(p.dataPedido),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _moeda(p.total),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF0B429),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${p.totalItens} item${p.totalItens != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withOpacity(0.3),
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

            // ── Separador pontilhado ─────────────────────────────────────
            if (_expandido || _ctrl.value > 0)
              FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(
                      40,
                      (i) => Expanded(
                        child: Container(
                          height: 1,
                          color: i.isEven
                              ? Colors.white.withOpacity(0.07)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Conteúdo expandido ──────────────────────────────────────
            SizeTransition(
              sizeFactor: _expansao,
              child: FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─ Secção: dados do cliente ──────────────────────
                      _SectionLabel(label: 'CLIENTE'),
                      const SizedBox(height: 8),
                      _AdminInfoGrid(entries: [
                        _InfoEntry(
                            icone: Icons.person_outline_rounded,
                            label: 'Nome',
                            valor: _nomeCliente),
                        if (p.telefone != null)
                          _InfoEntry(
                              icone: Icons.phone_outlined,
                              label: 'Telefone',
                              valor: p.telefone!),
                        if (p.email != null)
                          _InfoEntry(
                              icone: Icons.email_outlined,
                              label: 'Email',
                              valor: p.email!),
                        _InfoEntry(
                            icone: Icons.badge_outlined,
                            label: 'ID Usuário',
                            valor: '${p.idUsuario}'),
                      ]),

                      const SizedBox(height: 16),

                      // ─ Secção: itens ─────────────────────────────────
                      _SectionLabel(label: 'ITENS DO PEDIDO'),
                      const SizedBox(height: 8),
                      ...p.itens.map((item) => _AdminItemRow(item: item)),

                      const SizedBox(height: 16),

                      // ─ Secção: resumo financeiro ─────────────────────
                      _SectionLabel(label: 'RESUMO FINANCEIRO'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 1),
                        ),
                        child: Column(
                          children: [
                            _FinanceRow(
                                label: 'Total do pedido',
                                valor: _moeda(p.total)),
                            if (p.valorPagoManual > 0) ...[
                              _divider(),
                              _FinanceRow(
                                  label: 'Valor pago',
                                  valor: _moeda(p.valorPagoManual)),
                            ],
                            if (p.troco > 0) ...[
                              _divider(),
                              _FinanceRow(
                                  label: 'Troco',
                                  valor: _moeda(p.troco),
                                  corValor: const Color(0xFF2ECC71)),
                            ],
                            _divider(),
                            _FinanceRow(
                                label: 'TOTAL FINAL',
                                valor: _moeda(p.total),
                                destaque: true,
                                corValor: const Color(0xFFF0B429)),
                          ],
                        ),
                      ),

                      // ─ Secção: entrega (se houver) ───────────────────
                      if (p.bairro != null ||
                          p.pontoReferencia != null) ...[
                        const SizedBox(height: 16),
                        _SectionLabel(label: 'ENTREGA'),
                        const SizedBox(height: 8),
                        _AdminInfoGrid(entries: [
                          if (p.bairro != null)
                            _InfoEntry(
                                icone: Icons.location_city_outlined,
                                label: 'Bairro',
                                valor: p.bairro!),
                          if (p.pontoReferencia != null)
                            _InfoEntry(
                                icone: Icons.pin_drop_outlined,
                                label: 'Referência',
                                valor: p.pontoReferencia!),
                        ]),
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

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Divider(
            height: 1, color: Colors.white.withOpacity(0.06)),
      );
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFF0B429),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}

class _InfoEntry {
  final IconData icone;
  final String label;
  final String valor;
  const _InfoEntry(
      {required this.icone, required this.label, required this.valor});
}

class _AdminInfoGrid extends StatelessWidget {
  final List<_InfoEntry> entries;
  const _AdminInfoGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final entry = e.value;
          final isLast = e.key == entries.length - 1;
          return Column(
            children: [
              Row(
                children: [
                  Icon(entry.icone,
                      size: 14, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(width: 8),
                  Text('${entry.label}: ',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w500)),
                  Expanded(
                    child: Text(
                      entry.valor,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 6),
                Divider(
                    height: 1, color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 6),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AdminItemRow extends StatelessWidget {
  final ItemPedido item;
  const _AdminItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFF0B429).withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '${item.quantidade}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF0B429),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.nomeProduto,
              style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.3),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'MZN ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '@ MZN ${item.precoUnitario.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;
  final Color? corValor;

  const _FinanceRow({
    required this.label,
    required this.valor,
    this.destaque = false,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: destaque ? 12.5 : 12,
            fontWeight:
                destaque ? FontWeight.w700 : FontWeight.w400,
            color: destaque
                ? Colors.white
                : Colors.white.withOpacity(0.45),
            letterSpacing: destaque ? 0.5 : 0,
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            fontSize: destaque ? 15 : 13,
            fontWeight:
                destaque ? FontWeight.w800 : FontWeight.w500,
            color: corValor ??
                (destaque
                    ? Colors.white
                    : Colors.white.withOpacity(0.65)),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icone;
  final Color cor;
  final bool grande;

  const _MetricCard({
    required this.label,
    required this.valor,
    required this.icone,
    required this.cor,
    this.grande = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(grande ? 16 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161820),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cor.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: grande ? 40 : 34,
            height: grande ? 40 : 34,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone,
                size: grande ? 20 : 17, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: grande ? 16 : 14,
                    fontWeight: FontWeight.w800,
                    color: grande ? cor : Colors.white,
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
          ),
        ],
      ),
    );
  }
}

// ─── Enum: ordenação ──────────────────────────────────────────────────────────

enum _OrdemFiltro {
  maisRecente,
  maisAntigo,
  maiorValor,
  menorValor;

  String get rotulo {
    switch (this) {
      case _OrdemFiltro.maisRecente:
        return 'Mais recente';
      case _OrdemFiltro.maisAntigo:
        return 'Mais antigo';
      case _OrdemFiltro.maiorValor:
        return 'Maior valor';
      case _OrdemFiltro.menorValor:
        return 'Menor valor';
    }
  }
}