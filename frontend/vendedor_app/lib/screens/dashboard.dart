
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_sidebar.dart';
import '../services/sessao_service.dart';
import '../config/api_config.dart';

// TODO: Descomentar quando sync_events_service for migrado
// import '../services/sync_events_service.dart';

// TODO: Descomentar quando estoque_alerta_popup for migrado
// import '../widgets/estoque_alerta_popup.dart';

// TODO: Descomentar quando conectividade_indicator for migrado
// import '../widgets/conectividade_indicator.dart';

class DashboardVendasScreen extends StatefulWidget {
  const DashboardVendasScreen({super.key});

  @override
  State<DashboardVendasScreen> createState() => _DashboardVendasScreenState();
}

enum PeriodoFiltro { hoje, semana, mes, tresMeses, seisMeses, ano }

class _DashboardVendasScreenState extends State<DashboardVendasScreen> {
  // TODO: Reactivar quando sync_events_service for migrado
  // StreamSubscription<SyncEvent>? _syncEventsSubscription;
  // Timer? _reloadTimer;

final String _baseUrl = ApiConfig.dashboardUrl;


  PeriodoFiltro _filtroAtual = PeriodoFiltro.semana;
  bool _isLoading = true;
  int? _perfilUsuario;

  // Dados dos gráficos
  List<Map<String, dynamic>> _dadosPizza = [];
  List<Map<String, dynamic>> _dadosBarra = [];
  List<Map<String, dynamic>> _top5Produtos = [];
  List<Map<String, dynamic>> _produtosNaoVendidos = [];
  List<Map<String, dynamic>> _desempenhoFuncionarios = [];
List<Map<String, dynamic>> _dadosMarca = [];

  @override
  void initState() {
    super.initState();
    // 🔥 ADAPTAÇÃO: idPerfil não-nullable em UsuarioModel
    _perfilUsuario = SessaoService.instance.usuarioAtual?.idPerfil;
    _carregarDados();

    // TODO: Reactivar quando sync_events_service for migrado
    // _syncEventsSubscription =
    //     SyncEventsService.instance.eventStream.listen((event) {
    //   if (!mounted) return;
    //   _reloadTimer?.cancel();
    //   _reloadTimer = Timer(const Duration(seconds: 2), () {
    //     if (mounted) _carregarDados();
    //   });
    // });
  }

  @override
  void dispose() {
    // TODO: Reactivar quando sync_events_service for migrado
    // _reloadTimer?.cancel();
    // _syncEventsSubscription?.cancel();
    super.dispose();
  }

  // ── Utilitário: data de início conforme filtro ───────────────────────────

  DateTime _calcularDataInicio() {
    final hoje = DateTime.now();
    switch (_filtroAtual) {
      case PeriodoFiltro.hoje:
        return DateTime(hoje.year, hoje.month, hoje.day);
      case PeriodoFiltro.semana:
        return hoje.subtract(const Duration(days: 7));
      case PeriodoFiltro.mes:
        return DateTime(hoje.year, hoje.month - 1, hoje.day);
      case PeriodoFiltro.tresMeses:
        return DateTime(hoje.year, hoje.month - 3, hoje.day);
      case PeriodoFiltro.seisMeses:
        return DateTime(hoje.year, hoje.month - 6, hoje.day);
      case PeriodoFiltro.ano:
        return DateTime(hoje.year - 1, hoje.month, hoje.day);
    }
  }

  // ── Carregamento de dados via Spring Boot ────────────────────────────────

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    final dataInicio = _calcularDataInicio().toIso8601String();

    try {
      // Todas as chamadas em paralelo para melhor performance
      final resultados = await Future.wait([
        _get('$_baseUrl/vendas-por-categoria?dataInicio=$dataInicio'),
        _get('$_baseUrl/evolucao-vendas?dataInicio=$dataInicio'),
        _get('$_baseUrl/top5-produtos?dataInicio=$dataInicio'),
        _get('$_baseUrl/produtos-nao-vendidos?dataInicio=$dataInicio'),
        if (_perfilUsuario == 1)
          _get('$_baseUrl/desempenho-usuarios?dataInicio=$dataInicio'),
          _get('$_baseUrl/vendas-por-marca?dataInicio=$dataInicio'),
      ]);

      setState(() {
        _dadosPizza = _parseList(resultados[0]);
        _dadosBarra = _parseList(resultados[1]);
        _top5Produtos = _parseList(resultados[2]);
        _produtosNaoVendidos = _parseList(resultados[3]);
        _desempenhoFuncionarios =
            (_perfilUsuario == 1) ? _parseList(resultados[4]) : [];
        _isLoading = false;
        _dadosMarca = _parseList(resultados[5]); 
      });
    } catch (e) {
      debugPrint('Erro ao carregar dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Faz GET e retorna o body como String
  Future<String> _get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 200) return response.body;
    throw Exception('Erro HTTP ${response.statusCode} em $url');
  }

  /// Converte body JSON em List<Map<String, dynamic>>
  List<Map<String, dynamic>> _parseList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Build principal ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard de Vendas'),
            backgroundColor: Colors.deepOrange,
            actions: [
              // TODO: Descomentar quando conectividade_indicator for migrado
              // const ConectividadeIndicator(),
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                onPressed: () => _mostrarAnaliseDetalhada(context),
                tooltip: 'Análise Detalhada',
              ),
            ],
          ),
          drawer: const AppSidebar(currentRoute: '/dashboard'),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFiltroDropdown(),
                        const SizedBox(height: 20),
                        _buildResumoCards(),
                        const SizedBox(height: 20),
                        _buildGraficoBarras(),
                        const SizedBox(height: 30),
                        _buildGraficoPizza(),
                        const SizedBox(height: 30),
                         _buildGraficoMarcas(),
                        const SizedBox(height: 30),
                        _buildTop5Section(),
                        if (_perfilUsuario == 1) ...[
                          const SizedBox(height: 30),
                          _buildDesempenhoFuncionarios(),
                        ],
                      ],
                    ),
                  ),
                ),
        ),

        // TODO: Descomentar quando estoque_alerta_popup for migrado
        // const EstoqueAlertaPopup(),
      ],
    );
  }

  Widget _buildGraficoMarcas() {
  if (_dadosMarca.isEmpty) {
    return _buildEmptyState('Sem dados de marcas para este período.');
  }

  final colors = [
    Colors.indigo, Colors.teal, Colors.pink,
    Colors.lime, Colors.cyan, Colors.deepOrange,
  ];
  final total = _dadosMarca.fold<double>(
    0, (sum, item) => sum + ((item['total_vendas'] as num?)?.toDouble() ?? 0));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Vendas por Marca',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
        ),
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _dadosMarca.asMap().entries.map((entry) {
                    final valor = (entry.value['total_vendas'] as num).toDouble();
                    final pct = (valor / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      color: colors[entry.key % colors.length],
                      value: valor,
                      title: '$pct%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _dadosMarca.asMap().entries.map((entry) {
                final nome = entry.value['nome_marca'] as String;
                final valor = (entry.value['total_vendas'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Container(width: 12, height: 12,
                        color: colors[entry.key % colors.length]),
                    const SizedBox(width: 8),
                    Text('$nome\nMT ${valor.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11)),
                  ]),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ],
  );
}

  // ── Widgets de UI (sem alterações face ao original) ─────────────────────

  Widget _buildFiltroDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PeriodoFiltro>(
          value: _filtroAtual,
          isExpanded: true,
          onChanged: (value) {
            if (value != null) {
              setState(() => _filtroAtual = value);
              _carregarDados();
            }
          },
          items: const [
            DropdownMenuItem(value: PeriodoFiltro.hoje, child: Text('Hoje')),
            DropdownMenuItem(
                value: PeriodoFiltro.semana, child: Text('Últimos 7 dias')),
            DropdownMenuItem(
                value: PeriodoFiltro.mes, child: Text('Último Mês')),
            DropdownMenuItem(
                value: PeriodoFiltro.tresMeses,
                child: Text('Últimos 3 Meses')),
            DropdownMenuItem(
                value: PeriodoFiltro.seisMeses,
                child: Text('Últimos 6 Meses')),
            DropdownMenuItem(
                value: PeriodoFiltro.ano, child: Text('Último Ano')),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCards() {
    final totalVendas = _dadosBarra.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['total_vendas'] as num?)?.toDouble() ?? 0),
    );
    return _buildCard(
      'Total de Vendas',
      'MT ${totalVendas.toStringAsFixed(2)}',
      Icons.attach_money,
      Colors.green,
    );
  }

  Widget _buildCard(
      String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 32),
          const SizedBox(height: 8),
          Text(titulo,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(valor,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGraficoBarras() {
    if (_dadosBarra.isEmpty) {
      return _buildEmptyState('Sem dados de vendas para este período.');
    }

    final maxY = _dadosBarra
            .map((e) => (e['total_vendas'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evolução de Vendas',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade200, blurRadius: 6)
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < _dadosBarra.length) {
                        final date = DateTime.parse(
                            _dadosBarra[idx]['data'] as String);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(DateFormat('dd/MM').format(date),
                              style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData:
                  FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barGroups: _dadosBarra.asMap().entries.map((entry) {
                final valor =
                    (entry.value['total_vendas'] as num).toDouble();
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: valor,
                      color: Colors.blue,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                  showingTooltipIndicators: [0],
                );
              }).toList(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      'MT ${rod.toY.toStringAsFixed(2)}',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoPizza() {
    if (_dadosPizza.isEmpty) {
      return _buildEmptyState(
          'Sem dados de categoria para este período.');
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.amber
    ];
    final total = _dadosPizza.fold<double>(
        0,
        (sum, item) =>
            sum + ((item['total_vendas'] as num?)?.toDouble() ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vendas por Categoria',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade200, blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _dadosPizza.asMap().entries.map((entry) {
                      final valor =
                          (entry.value['total_vendas'] as num).toDouble();
                      final percentual =
                          (valor / total * 100).toStringAsFixed(1);
                      return PieChartSectionData(
                        color: colors[entry.key % colors.length],
                        value: valor,
                        title: '$percentual%',
                        radius: 50,
                        titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _dadosPizza.asMap().entries.map((entry) {
                  final nome =
                      entry.value['nome_categoria'] as String;
                  final valor =
                      (entry.value['total_vendas'] as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                            width: 12,
                            height: 12,
                            color: colors[entry.key % colors.length]),
                        const SizedBox(width: 8),
                        Text(
                            '$nome\nMT ${valor.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTop5Section() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Top 5 Produtos Mais Vendidos',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _mostrarAnaliseDetalhada(context),
              icon: const Icon(Icons.analytics),
              label: const Text('Ver Detalhes'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._top5Produtos.map((produto) => _buildProdutoCard(produto)),
      ],
    );
  }

  Widget _buildProdutoCard(Map<String, dynamic> produto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produto['nome_produto'] as String,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Quantidade: ${produto['quantidade_vendida']} | '
                  'Receita: MT ${(produto['receita_total'] as num).toStringAsFixed(2)}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${produto['num_pedidos']} pedidos',
              style: TextStyle(
                  color: Colors.green.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesempenhoFuncionarios() {
    if (_desempenhoFuncionarios.isEmpty) {
      return _buildEmptyState(
          'Sem dados de desempenho para este período.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.leaderboard, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text(
              'Desempenho de usuários',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._desempenhoFuncionarios.asMap().entries.map((entry) {
          final index = entry.key;
          final func = entry.value;

          final medalha = index == 0
              ? '🥇'
              : index == 1
                  ? '🥈'
                  : index == 2
                      ? '🥉'
                      : '${index + 1}º';
          final corBorda = index == 0
              ? Colors.amber
              : index == 1
                  ? Colors.grey
                  : index == 2
                      ? Colors.orange.shade700
                      : Colors.blue.shade100;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: corBorda, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(medalha,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            func['cargo'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            func['nome_completo'] as String,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${func['total_pedidos']} pedidos em '
                            '${func['dias_ativos']} dias',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'MT ${(func['total_vendas'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (func['total_vendas'] as num) /
                          (_desempenhoFuncionarios
                              .first['total_vendas'] as num),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.teal
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(String mensagem) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(mensagem,
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _mostrarAnaliseDetalhada(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Análise Completa de Produtos',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSecaoAnalise(
                      'Top 5 Mais Vendidos', _top5Produtos, Colors.green),
                  const SizedBox(height: 20),
                  _buildSecaoAnalise(
                    'Produtos Sem Vendas (${_produtosNaoVendidos.length})',
                    _produtosNaoVendidos,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoAnalise(String titulo,
      List<Map<String, dynamic>> produtos, Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cor)),
        const SizedBox(height: 8),
        if (produtos.isEmpty)
          const Text('Nenhum produto nesta categoria.')
        else
          ...produtos.map((p) {
            if (p.containsKey('quantidade_vendida')) {
              return ListTile(
                title: Text(p['nome_produto'] as String),
                subtitle: Text(
                    'Vendidos: ${p['quantidade_vendida']} | '
                    'Receita: MT ${(p['receita_total'] as num).toStringAsFixed(2)}'),
                trailing: Chip(
                  label: Text('${p['num_pedidos']} pedidos'),
                  backgroundColor: Colors.green.shade50,
                ),
              );
            } else {
              return ListTile(
                title: Text(p['nome_produto'] as String),
                subtitle: Text(
                    'Estoque: ${p['quantidade_estoque']} | '
                    'Preço: MT ${(p['preco'] as num).toStringAsFixed(2)}'),
                trailing: const Icon(Icons.warning_amber,
                    color: Colors.orange),
              );
            }
          }),
      ],
    );
  }
}