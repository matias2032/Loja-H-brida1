import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'criar_pedido.dart';

class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({Key? key}) : super(key: key);

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen>
    with SingleTickerProviderStateMixin {
  final CarrinhoService _service = CarrinhoService();
  final CarrinhoContadorService _contador = CarrinhoContadorService.instance;

  CarrinhoModel? _carrinho;
  bool _loading = true;
  String? _erro;

  // Controla quais itens estão a ser atualizados (evita double-tap)
  final Set<int> _atualizando = {};

  // Debounce para o campo manual de quantidade
  final Map<int, Timer> _debounceTimers = {};
  final Map<int, TextEditingController> _qtyControllers = {};

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _carregarCarrinho();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _carregarCarrinho() async {
  setState(() {
    _loading = true;
    _erro = null;
  });

  try {
    await _contador.recarregarSeNecessario();
    final idCarrinho = _contador.idCarrinhoAtivo;

    if (idCarrinho == null) {
      setState(() {
        _carrinho = null;
        _loading = false;
      });
      _fadeCtrl.forward(from: 0);
      return;
    }

    // Substituir buscarCarrinho(idCarrinho) por buscarCarrinhoActivo()
    // que usa o endpoint GET /activo já existente e funcional
    final carrinho = await _service.buscarCarrinhoActivo();

    if (carrinho == null) {
      setState(() {
        _carrinho = null;
        _loading = false;
      });
      _fadeCtrl.forward(from: 0);
      return;
    }

    _sincronizarControllers(carrinho);
    setState(() {
      _carrinho = carrinho;
      _loading = false;
    });
    _fadeCtrl.forward(from: 0);
  } catch (e) {
    setState(() {
      _erro = e.toString();
      _loading = false;
    });
  }
}

  /// Cria / atualiza os TextEditingControllers para cada item do carrinho.
  void _sincronizarControllers(CarrinhoModel carrinho) {
    final idsAtuais = carrinho.itens.map((i) => i.idProduto).toSet();

    // Remove controllers de itens que já não existem
    _qtyControllers.removeWhere((id, ctrl) {
      if (!idsAtuais.contains(id)) {
        ctrl.dispose();
        return true;
      }
      return false;
    });

    for (final item in carrinho.itens) {
      final id = item.idProduto;
      if (!_qtyControllers.containsKey(id)) {
        _qtyControllers[id] = TextEditingController(
          text: item.quantidade.toString(),
        );
      } else {
        // Só atualiza se o valor divergir (evita reset durante edição)
        if (_qtyControllers[id]!.text != item.quantidade.toString()) {
          _qtyControllers[id]!.text = item.quantidade.toString();
        }
      }
    }
  }

  // ── Ações ──────────────────────────────────────────────────────────────────

  Future<void> _alterarQuantidade(ItemCarrinho item, int novaQtd) async {
    if (_atualizando.contains(item.idProduto)) return;
    if (novaQtd < 1) {
      _confirmarRemocao(item);
      return;
    }

    setState(() => _atualizando.add(item.idProduto));

    try {
      final atualizado = await _service.atualizarQuantidade(
        _carrinho!.idCarrinho,
        item.idProduto,
        novaQtd,
      );
      _sincronizarControllers(atualizado);
      setState(() => _carrinho = atualizado);

      // Atualiza badge do menu
      _contador.invalidarCache();
      await _contador.recarregarSeNecessario();
    } on EstoqueInsuficienteException catch (e) {
      _snack(
        '⚠️ Estoque insuficiente. Máximo disponível: ${e.estoqueDisponivel}',
        Colors.orange,
      );
      // Reverte o controller para a quantidade atual do item
      _qtyControllers[item.idProduto]?.text = item.quantidade.toString();
    } catch (e) {
      _snack('Erro ao atualizar quantidade: $e', Colors.red);
      _qtyControllers[item.idProduto]?.text = item.quantidade.toString();
    } finally {
      setState(() => _atualizando.remove(item.idProduto));
    }
  }

  Future<void> _removerItem(ItemCarrinho item) async {
    if (_atualizando.contains(item.idProduto)) return;
    setState(() => _atualizando.add(item.idProduto));

    try {
      await _service.removerItem(_carrinho!.idCarrinho, item.idProduto);

      _contador.invalidarCache();
      await _contador.recarregarSeNecessario();

      // Se era o último item, o backend elimina o carrinho — recarrega estado
      await _carregarCarrinho();
    } catch (e) {
      _snack('Erro ao remover item: $e', Colors.red);
      setState(() => _atualizando.remove(item.idProduto));
    }
  }

  void _confirmarRemocao(ItemCarrinho item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover item?'),
        content: Text(
          'Deseja remover "${item.nomeProduto}" do carrinho?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removerItem(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _irParaCheckout() {
    final idCarrinho = _carrinho?.idCarrinho;
    if (idCarrinho == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CriarPedidoScreen(idCarrinho: idCarrinho),
      ),
    ).then((_) => _carregarCarrinho());
  }

  // ── Debounce para input manual ─────────────────────────────────────────────

  void _onQtdManualChange(ItemCarrinho item, String value) {
    _debounceTimers[item.idProduto]?.cancel();
    _debounceTimers[item.idProduto] = Timer(
      const Duration(milliseconds: 800),
      () {
        final novaQtd = int.tryParse(value);
        if (novaQtd == null || novaQtd == item.quantidade) return;
        _alterarQuantidade(item, novaQtd);
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _snack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  double get _totalLocal {
    if (_carrinho == null) return 0;
    return _carrinho!.itens.fold(0, (s, i) => s + i.subtotal);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _carrinho != null && _carrinho!.itens.isNotEmpty
          ? _buildRodape()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final totalItens = _carrinho?.totalItens ?? 0;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carrinho',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (totalItens > 0)
            Text(
              '$totalItens ${totalItens == 1 ? 'item' : 'itens'}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[200], height: 1),
      ),
      actions: [
        if (_carrinho != null && _carrinho!.itens.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A2E)),
            tooltip: 'Atualizar',
            onPressed: _carregarCarrinho,
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return _buildErro();
    }

    if (_carrinho == null || _carrinho!.itens.isEmpty) {
      return _buildVazio();
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _carrinho!.itens.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildItemCard(_carrinho!.itens[index]),
      ),
    );
  }

  // ── Cards de item ──────────────────────────────────────────────────────────

  Widget _buildItemCard(ItemCarrinho item) {
    final atualizando = _atualizando.contains(item.idProduto);
    final ctrl = _qtyControllers[item.idProduto];

    return AnimatedOpacity(
      opacity: atualizando ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Linha superior: imagem + nome + botão remover ─────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem do produto
                  if (item.imagemUrl != null && item.imagemUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.imagemUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImagem(),
                      ),
                    )
                  else
                    _placeholderImagem(),

                  const SizedBox(width: 12),

                  // Nome e preço unitário
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nomeProduto,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MZN ${item.precoUnitario.toStringAsFixed(2)} / un.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),

                  // Ícone de remover / loading
                  atualizando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          tooltip: 'Remover item',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _confirmarRemocao(item),
                        ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Linha inferior: controlo quantidade + subtotal ────────────
              Row(
                children: [
                  _buildSelectorQuantidade(item, ctrl),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      Text(
                        'MZN ${item.subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
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
    );
  }

  Widget _buildSelectorQuantidade(
      ItemCarrinho item, TextEditingController? ctrl) {
    final atualizando = _atualizando.contains(item.idProduto);

    return Row(
      children: [
        // Botão −  (vermelho quando qty == 1, pois aciona remoção)
        _botaoQtd(
          icon: Icons.remove,
          enabled: !atualizando,
          onTap: () => _alterarQuantidade(item, item.quantidade - 1),
          danger: item.quantidade == 1,
        ),

        // Campo manual
        Container(
          width: 52,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ctrl != null
              ? TextField(
                  controller: ctrl,
                  enabled: !atualizando,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => _onQtdManualChange(item, v),
                )
              : const SizedBox.shrink(),
        ),

        // Botão +
        _botaoQtd(
          icon: Icons.add,
          enabled: !atualizando,
          onTap: () => _alterarQuantidade(item, item.quantidade + 1),
        ),
      ],
    );
  }

  Widget _botaoQtd({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final bg = !enabled
        ? Colors.grey[200]!
        : danger
            ? Colors.red[50]!
            : const Color(0xFF1A1A2E);
    final fg = !enabled
        ? Colors.grey[400]!
        : danger
            ? Colors.red[400]!
            : Colors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );
  }

  Widget _placeholderImagem() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.image_not_supported_outlined,
          size: 28, color: Colors.grey[400]),
    );
  }

  // ── Estado vazio ───────────────────────────────────────────────────────────

  Widget _buildVazio() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shopping_cart_outlined,
                    size: 64, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              const Text(
                'O carrinho está vazio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Adicione produtos a partir do menu\npara iniciar uma compra.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar ao Menu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Estado de erro ─────────────────────────────────────────────────────────

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            Text(_erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _carregarCarrinho,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rodapé com total e botão de checkout ───────────────────────────────────

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${_carrinho!.totalItens} '
                  '${_carrinho!.totalItens == 1 ? 'item' : 'itens'})',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  'MZN ${_totalLocal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _irParaCheckout,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text(
                  'Fazer Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Exceção tipada para estoque insuficiente (lançada pelo CarrinhoService)
// ════════════════════════════════════════════════════════════════════════════

class EstoqueInsuficienteException implements Exception {
  final int estoqueDisponivel;
  const EstoqueInsuficienteException(this.estoqueDisponivel);
}