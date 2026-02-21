//movimento_estoque.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/movimento_estoque_model.dart';
import '../services/movimento_estoque_service.dart';
import '../widgets/app_sidebar.dart'; 

// ─────────────────────────────────────────────
// MODELO ENRIQUECIDO (adapte ao seu backend)
// ─────────────────────────────────────────────
class MovimentoEstoqueEnriquecido {
  final MovimentoEstoque movimento;
  final String nomeProduto;
  final String nomeUsuario;
  final String? imagemProdutoUrl;

  MovimentoEstoqueEnriquecido({
    required this.movimento,
    required this.nomeProduto,
    required this.nomeUsuario,
    this.imagemProdutoUrl,
  });
}

// ─────────────────────────────────────────────
// FILTROS DE PERÍODO
// ─────────────────────────────────────────────
enum FiltroPeriodo {
  hoje,
  ultimos7,
  ultimos15,
  ultimos30,
  ultimos90,
  ultimos180,
  ultimos365,
}

extension FiltroPeriodoExt on FiltroPeriodo {
  String get label {
    switch (this) {
      case FiltroPeriodo.hoje:
        return 'Hoje';
      case FiltroPeriodo.ultimos7:
        return '7 dias';
      case FiltroPeriodo.ultimos15:
        return '15 dias';
      case FiltroPeriodo.ultimos30:
        return '1 mês';
      case FiltroPeriodo.ultimos90:
        return '3 meses';
      case FiltroPeriodo.ultimos180:
        return '6 meses';
      case FiltroPeriodo.ultimos365:
        return '1 ano';
    }
  }

  int get dias {
    switch (this) {
      case FiltroPeriodo.hoje:
        return 0;
      case FiltroPeriodo.ultimos7:
        return 7;
      case FiltroPeriodo.ultimos15:
        return 15;
      case FiltroPeriodo.ultimos30:
        return 30;
      case FiltroPeriodo.ultimos90:
        return 90;
      case FiltroPeriodo.ultimos180:
        return 180;
      case FiltroPeriodo.ultimos365:
        return 365;
    }
  }

  DateTime get dataInicio {
    final agora = DateTime.now();
    if (this == FiltroPeriodo.hoje) {
      return DateTime(agora.year, agora.month, agora.day);
    }
    return agora.subtract(Duration(days: dias));
  }
}

// ─────────────────────────────────────────────
// TELA PRINCIPAL
// ─────────────────────────────────────────────
class MovimentoEstoqueListScreen extends StatefulWidget {
  const MovimentoEstoqueListScreen({Key? key}) : super(key: key);

  @override
  State<MovimentoEstoqueListScreen> createState() =>
      _MovimentoEstoqueListScreenState();
}

class _MovimentoEstoqueListScreenState
    extends State<MovimentoEstoqueListScreen> with TickerProviderStateMixin {
  // ── Serviço ──────────────────────────────────
  final MovimentoEstoqueService _service = MovimentoEstoqueService();

  // ── Estado ───────────────────────────────────
  List<MovimentoEstoqueEnriquecido> _todos = [];
  List<MovimentoEstoqueEnriquecido> _filtrados = [];
  bool _isLoading = true;
  String? _erro;

  // ── Filtros ──────────────────────────────────
  FiltroPeriodo _periodoSelecionado = FiltroPeriodo.ultimos30;
  String? _tipoSelecionado; // null = todos
  String _buscaTexto = '';
  final TextEditingController _buscaController = TextEditingController();

  // ── Animação ─────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Formatadores ─────────────────────────────
  final _fmtData = DateFormat('dd/MM/yyyy');
  final _fmtHora = DateFormat('HH:mm');
  final _fmtDataHora = DateFormat('dd/MM/yyyy • HH:mm');

  // ─────────────────────────────────────────────
  // INIT / DISPOSE
  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _carregarMovimentos();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // CARREGAMENTO
  // ─────────────────────────────────────────────
Future<void> _carregarMovimentos() async {
  setState(() {
    _isLoading = true;
    _erro = null;
  });

  try {
    final agora = DateTime.now();
    final inicio = _periodoSelecionado.dataInicio;

    final List<MovimentoEstoque> movimentos =
        await _service.listarPorPeriodo(inicio, agora);

    setState(() {
      _todos = movimentos.map((m) => MovimentoEstoqueEnriquecido(
        movimento: m,
        // Enquanto o backend não retornar nome, exibe o ID
      nomeProduto: m.nomeProduto ?? 'Produto #${m.idProduto}',
nomeUsuario: m.nomeUsuario ?? 'Usuário #${m.idUsuario}',
      )).toList();
      _isLoading = false;
    });

    _aplicarFiltros();
    _fadeController.forward(from: 0);
  } catch (e) {
    setState(() {
      _isLoading = false;
      _erro = 'Erro ao carregar movimentos: $e';
    });
  }
}
  // ─────────────────────────────────────────────
  // FILTROS
  // ─────────────────────────────────────────────
  void _aplicarFiltros() {
    final dataInicio = _periodoSelecionado.dataInicio;

    setState(() {
      _filtrados = _todos.where((item) {
        final data = item.movimento.dataMovimento;
        final dentroDoperiodo =
            data != null && !data.isBefore(dataInicio);

        final tipoOk = _tipoSelecionado == null ||
            item.movimento.tipoMovimento == _tipoSelecionado;

        final busca = _buscaTexto.trim().toLowerCase();
        final buscaOk = busca.isEmpty ||
            item.nomeProduto.toLowerCase().contains(busca) ||
            item.nomeUsuario.toLowerCase().contains(busca) ||
            (item.movimento.motivo?.toLowerCase().contains(busca) ?? false);

        return dentroDoperiodo && tipoOk && buscaOk;
      }).toList();

      // Ordenar do mais recente ao mais antigo
      _filtrados.sort((a, b) {
        final da = a.movimento.dataMovimento ?? DateTime(2000);
        final db = b.movimento.dataMovimento ?? DateTime(2000);
        return db.compareTo(da);
      });
    });

    _fadeController.forward(from: 0);
  }

  // ─────────────────────────────────────────────
  // ESTATÍSTICAS
  // ─────────────────────────────────────────────
  Map<String, dynamic> get _estatisticas {
    final entradas =
        _filtrados.where((m) => m.movimento.tipoMovimento == 'entrada');
    final saidas =
        _filtrados.where((m) => m.movimento.tipoMovimento == 'saida');
    final ajustes =
        _filtrados.where((m) => m.movimento.tipoMovimento == 'ajuste');

    final totalEntrada =
        entradas.fold<int>(0, (s, m) => s + m.movimento.quantidade);
    final totalSaida =
        saidas.fold<int>(0, (s, m) => s + m.movimento.quantidade);
    final totalAjuste =
        ajustes.fold<int>(0, (s, m) => s + m.movimento.quantidade);

    return {
      'total': _filtrados.length,
      'entradas': entradas.length,
      'saidas': saidas.length,
      'ajustes': ajustes.length,
      'qtdEntrada': totalEntrada,
      'qtdSaida': totalSaida,
      'qtdAjuste': totalAjuste,
    };
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
 @override
Widget build(BuildContext context) {
  final stats = _estatisticas;

  return Scaffold(
    backgroundColor: const Color(0xFF0F1117),
    // Definindo a rota correta para marcar o item ativo na sidebar
    drawer: const AppSidebar(currentRoute: 'movimentos_estoque'), 
    
    body: Builder(
      builder: (context) => Column(
        children: [
          _buildHeader(context), // Passa o contexto do Builder para o header
          _buildFiltrosPeriodo(),
          _buildBarraBusca(),
          _buildFiltrosTipo(),
          _buildCards(stats),
          
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _erro != null
                    ? _buildErro()
                    : _filtrados.isEmpty
                        ? _buildVazio()
                        : _buildLista(),
          ),
        ],
      ),
    ),
  );
}

Widget _buildHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.fromLTRB(8, 48, 20, 16),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1D2E), Color(0xFF0F1117)],
      ),
    ),
    child: Row(
      children: [
        // Botão para abrir a Sidebar
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Abrir Menu',
        ),

        const SizedBox(width: 4),

        // Ícone decorativo
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.swap_vert_rounded,
              color: Colors.white, size: 24),
        ),

        const SizedBox(width: 14),

        // Títulos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Movimentos de Estoque',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18, // Ajustado levemente para caber melhor com o menu
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Histórico completo de alterações',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Botão atualizar
        IconButton(
          onPressed: _carregarMovimentos,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white60),
          tooltip: 'Atualizar',
        ),
      ],
    ),
  );
}
  // ─────────────────────────────────────────────
  // FILTROS DE PERÍODO (chips horizontais)
  // ─────────────────────────────────────────────
  Widget _buildFiltrosPeriodo() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: FiltroPeriodo.values.map((filtro) {
          final selecionado = filtro == _periodoSelecionado;
          return GestureDetector(
       
onTap: () {
  setState(() => _periodoSelecionado = filtro);
  _carregarMovimentos(); // ← recarrega do backend com novo período
},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: selecionado
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                      )
                    : null,
                color: selecionado ? null : const Color(0xFF1E2130),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selecionado
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Text(
                filtro.label,
                style: TextStyle(
                  color: selecionado
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: selecionado
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BARRA DE BUSCA
  // ─────────────────────────────────────────────
  Widget _buildBarraBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _buscaController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (v) {
          _buscaTexto = v;
          _aplicarFiltros();
        },
        decoration: InputDecoration(
          hintText: 'Buscar por produto, usuário ou motivo...',
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3)),
          suffixIcon: _buscaTexto.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.white.withOpacity(0.4), size: 18),
                  onPressed: () {
                    _buscaController.clear();
                    _buscaTexto = '';
                    _aplicarFiltros();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1E2130),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTROS DE TIPO
  // ─────────────────────────────────────────────
  Widget _buildFiltrosTipo() {
    final tipos = [
      {'key': null, 'label': 'Todos', 'icon': Icons.list_rounded},
      {
        'key': 'entrada',
        'label': 'Entradas',
        'icon': Icons.trending_up_rounded
      },
      {'key': 'saida', 'label': 'Saídas', 'icon': Icons.trending_down_rounded},
      {'key': 'ajuste', 'label': 'Ajustes', 'icon': Icons.tune_rounded},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: tipos.map((tipo) {
          final key = tipo['key'] as String?;
          final selecionado = _tipoSelecionado == key;
          final color = _corTipo(key ?? '');

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _tipoSelecionado = key);
                _aplicarFiltros();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selecionado
                      ? color.withOpacity(0.18)
                      : const Color(0xFF1E2130),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selecionado
                        ? color.withOpacity(0.6)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      tipo['icon'] as IconData,
                      color: selecionado
                          ? color
                          : Colors.white.withOpacity(0.3),
                      size: 18,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tipo['label'] as String,
                      style: TextStyle(
                        color: selecionado
                            ? color
                            : Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CARDS DE ESTATÍSTICAS
  // ─────────────────────────────────────────────
  Widget _buildCards(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _buildStatCard(
            label: 'Total',
            valor: '${stats['total']}',
            sublabel: 'movimentos',
            cor: const Color(0xFF6C63FF),
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            label: 'Entradas',
            valor: '+${stats['qtdEntrada']}',
            sublabel: '${stats['entradas']} mov.',
            cor: const Color(0xFF4CAF82),
            icon: Icons.arrow_downward_rounded,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            label: 'Saídas',
            valor: '-${stats['qtdSaida']}',
            sublabel: '${stats['saidas']} mov.',
            cor: const Color(0xFFEF5350),
            icon: Icons.arrow_upward_rounded,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            label: 'Ajustes',
            valor: '~${stats['qtdAjuste']}',
            sublabel: '${stats['ajustes']} mov.',
            cor: const Color(0xFFFFA726),
            icon: Icons.tune_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String valor,
    required String sublabel,
    required Color cor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cor, size: 16),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                color: cor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTA
  // ─────────────────────────────────────────────
  Widget _buildLista() {
    // Agrupar por data
    final Map<String, List<MovimentoEstoqueEnriquecido>> grupos = {};
    for (final item in _filtrados) {
      final data = item.movimento.dataMovimento;
      final chave = data != null ? _fmtData.format(data) : 'Sem data';
      grupos.putIfAbsent(chave, () => []).add(item);
    }

    final datas = grupos.keys.toList();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: datas.length,
        itemBuilder: (context, i) {
          final data = datas[i];
          final itens = grupos[data]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeparadorData(data),
              ...itens.map((item) => _buildCard(item)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeparadorData(String data) {
    final hoje = _fmtData.format(DateTime.now());
    final ontem = _fmtData
        .format(DateTime.now().subtract(const Duration(days: 1)));
    String label = data;
    if (data == hoje) label = 'Hoje';
    if (data == ontem) label = 'Ontem';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Colors.white.withOpacity(0.07),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(MovimentoEstoqueEnriquecido item) {
    final mov = item.movimento;
    final cor = _corTipo(mov.tipoMovimento);
    final icone = _iconeTipo(mov.tipoMovimento);
    final sinal = mov.tipoMovimento == 'entrada'
        ? '+'
        : mov.tipoMovimento == 'saida'
            ? '-'
            : '~';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _mostrarDetalhe(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ícone do tipo ──────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor, size: 20),
              ),
              const SizedBox(width: 12),

              // ── Informações principais ─────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Produto
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.nomeProduto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Quantidade
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$sinal${mov.quantidade}',
                            style: TextStyle(
                              color: cor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Usuário + tipo
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 12,
                            color: Colors.white.withOpacity(0.35)),
                        const SizedBox(width: 4),
                        Text(
                          item.nomeUsuario,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _labelTipo(mov.tipoMovimento),
                            style: TextStyle(
                              color: cor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Estoque anterior → novo + hora
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 12,
                            color: Colors.white.withOpacity(0.3)),
                        const SizedBox(width: 4),
                        Text(
                          '${mov.quantidadeAnterior}  →  ${mov.quantidadeNova}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time_rounded,
                            size: 11,
                            color: Colors.white.withOpacity(0.25)),
                        const SizedBox(width: 3),
                        Text(
                          mov.dataMovimento != null
                              ? _fmtHora.format(mov.dataMovimento!)
                              : '--:--',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    // Motivo (se houver)
                    if (mov.motivo != null && mov.motivo!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 11,
                              color: Colors.white.withOpacity(0.25)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              mov.motivo!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MODAL DE DETALHE
  // ─────────────────────────────────────────────
  void _mostrarDetalhe(MovimentoEstoqueEnriquecido item) {
    final mov = item.movimento;
    final cor = _corTipo(mov.tipoMovimento);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header do modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_iconeTipo(mov.tipoMovimento),
                        color: cor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhe do Movimento',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '#${mov.idMovimento ?? '—'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.07), thickness: 1),

            // Campos do detalhe
            _buildLinhaDetalhe(
                Icons.inventory_2_outlined, 'Produto', item.nomeProduto, cor),
            _buildLinhaDetalhe(
                Icons.person_outline_rounded, 'Usuário', item.nomeUsuario, cor),
            _buildLinhaDetalhe(Icons.label_outline_rounded, 'Tipo',
                _labelTipo(mov.tipoMovimento), cor),
            _buildLinhaDetalhe(Icons.numbers_rounded, 'Quantidade',
                '${mov.quantidade} unidades', cor),
            _buildLinhaDetalhe(
              Icons.swap_horiz_rounded,
              'Estoque anterior → novo',
              '${mov.quantidadeAnterior}  →  ${mov.quantidadeNova}',
              cor,
            ),
            if (mov.motivo != null && mov.motivo!.isNotEmpty)
              _buildLinhaDetalhe(
                  Icons.chat_bubble_outline_rounded, 'Motivo', mov.motivo!, cor),
            _buildLinhaDetalhe(
              Icons.calendar_today_rounded,
              'Data e hora',
              mov.dataMovimento != null
                  ? _fmtDataHora.format(mov.dataMovimento!)
                  : '—',
              cor,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaDetalhe(
      IconData icon, String label, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cor.withOpacity(0.7)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ESTADOS AUXILIARES
  // ─────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF6C63FF),
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Carregando movimentos...',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.withOpacity(0.6), size: 48),
          const SizedBox(height: 16),
          Text(
            _erro ?? 'Erro desconhecido',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _carregarMovimentos,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
            label: const Text('Tentar novamente',
                style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              color: Colors.white.withOpacity(0.15), size: 56),
          const SizedBox(height: 16),
          Text(
            'Nenhum movimento encontrado',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tente ajustar os filtros ou o período',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS DE TIPO
  // ─────────────────────────────────────────────
  Color _corTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return const Color(0xFF4CAF82);
      case 'saida':
        return const Color(0xFFEF5350);
      case 'ajuste':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  IconData _iconeTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return Icons.arrow_downward_rounded;
      case 'saida':
        return Icons.arrow_upward_rounded;
      case 'ajuste':
        return Icons.tune_rounded;
      default:
        return Icons.swap_vert_rounded;
    }
  }

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'ENTRADA';
      case 'saida':
        return 'SAÍDA';
      case 'ajuste':
        return 'AJUSTE';
      default:
        return tipo.toUpperCase();
    }
  }

  
}