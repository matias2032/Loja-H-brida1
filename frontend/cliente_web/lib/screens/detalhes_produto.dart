import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../controllers/pedido_ativo_controller.dart';
import '../widgets/pedido_ativo_banner.dart';


class DetalhesProdutoScreen extends StatefulWidget {
  final Produto produto;
  final List<Marca> marcas;
  final List<Categoria> categorias;

  const DetalhesProdutoScreen({
    Key? key,
    required this.produto,
    required this.marcas,
    required this.categorias,
  }) : super(key: key);

  @override
  State<DetalhesProdutoScreen> createState() => _DetalhesProdutoScreenState();
}

class _DetalhesProdutoScreenState extends State<DetalhesProdutoScreen> {
  final PedidoService _pedidoService = PedidoService();

  int _quantidade = 1;
  bool _isCriandoPedido = false;

  // ─── Getters ─────────────────────────────────────────────────────────────

  Produto get produto => widget.produto;
  double get precoEfetivo => produto.precoPromocional ?? produto.preco;
  double get totalParcial => precoEfetivo * _quantidade;
  bool get temPromocao => produto.precoPromocional != null;
  Pedido? get _pedidoAtivo => PedidoAtivoController.instance.pedidoAtivo.value;
bool get _temPedidoAtivo => _pedidoAtivo != null;

  String get nomesMarcas {
    if (produto.marcas.isEmpty) return 'Sem marca';
    return produto.marcas
        .map((id) => widget.marcas
            .firstWhere(
              (m) => m.idMarca == id,
              orElse: () => Marca(idMarca: id, nomeMarca: 'Desconhecida'),
            )
            .nomeMarca)
        .join(', ');
  }

  String get nomesCategorias {
    if (produto.categorias.isEmpty) return 'Sem categoria';
    return produto.categorias
        .map((id) => widget.categorias
            .firstWhere(
              (c) => c.idCategoria == id,
              orElse: () =>
                  Categoria(idCategoria: id, nomeCategoria: 'Desconhecida'),
            )
            .nomeCategoria)
        .join(', ');
  }

  // ─── Quantidade ───────────────────────────────────────────────────────────

  void _aumentarQuantidade() {
    if (_quantidade < produto.quantidadeEstoque) {
      setState(() => _quantidade++);
    } else {
      _mostrarSnack('Quantidade máxima em estoque atingida', Colors.orange);
    }
  }

  void _diminuirQuantidade() {
    if (_quantidade > 1) setState(() => _quantidade--);
  }

  void _definirQuantidade(int valor) {
    if (valor < 1) return;
    if (valor > produto.quantidadeEstoque) {
      _mostrarSnack(
          'Quantidade máxima disponível: ${produto.quantidadeEstoque}',
          Colors.orange);
      setState(() => _quantidade = produto.quantidadeEstoque);
      return;
    }
    setState(() => _quantidade = valor);
  }

  // ─── Criação de pedido ────────────────────────────────────────────────────

Future<void> _criarPedido() async {
  if (_isCriandoPedido) return;

  final confirmado = await _mostrarDialogoConfirmacao();
  if (!confirmado) return;

  setState(() => _isCriandoPedido = true);

  try {
    Pedido pedidoResultado;

    if (_temPedidoAtivo) {
      // ── Adiciona ao pedido activo existente ──────────────────────────
      final item = ItemPedido(
        idProduto: produto.idProduto!,
        nomeProduto: produto.nomeProduto,
        quantidade: _quantidade,
        precoUnitario: precoEfetivo,
        subtotal: totalParcial,
      );
      pedidoResultado = await _pedidoService.adicionarItem(
        _pedidoAtivo!.idPedido!,
        item,
      );
      // Actualiza o controller com o pedido actualizado
      PedidoAtivoController.instance.definir(pedidoResultado);

      _mostrarSnack(
        '✅ Item adicionado ao pedido ${pedidoResultado.reference ?? ''}! '
        'Total: MZN ${pedidoResultado.total.toStringAsFixed(2)}',
        Colors.green,
      );
    } else {
      // ── Cria um novo pedido ──────────────────────────────────────────
      final novoPedido = Pedido(
          idUsuario: SessaoService.instance.idUsuario!,   // TODO: substituir pelo id do utilizador autenticado
        idTipoPagamento: 1,
        statusPedido: 'por finalizar',
        itens: [
          ItemPedido(
            idProduto: produto.idProduto!,
            nomeProduto: produto.nomeProduto,
            quantidade: _quantidade,
            precoUnitario: precoEfetivo,
            subtotal: totalParcial,
          ),
        ],
      );
      pedidoResultado = await _pedidoService.criarPedido(novoPedido);
      // Regista como pedido activo
      PedidoAtivoController.instance.definir(pedidoResultado);

      _mostrarSnack(
        '✅ Pedido ${pedidoResultado.reference ?? ''} criado! '
        'Total: MZN ${pedidoResultado.total.toStringAsFixed(2)}',
        Colors.green,
      );
    }

    if (mounted) Navigator.pop(context, pedidoResultado);
  } catch (e) {
    _mostrarSnack('Erro: $e', Colors.red);
  } finally {
    if (mounted) setState(() => _isCriandoPedido = false);
  }
}

Future<bool> _mostrarDialogoConfirmacao() async {
  final pedidoAtivo = _pedidoAtivo;
  final adicionando = pedidoAtivo != null;

  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(adicionando ? 'Adicionar ao Pedido' : 'Confirmar Pedido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Badge do pedido activo ──────────────────────────────
              if (adicionando) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart,
                          size: 16, color: Color(0xFF1A1A2E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pedido activo: ${pedidoAtivo.reference ?? '—'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Detalhes do item ────────────────────────────────────
              Text(produto.nomeProduto,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _dialogRow('Quantidade:', '$_quantidade'),
              _dialogRow('Preço unitário:',
                  'MZN ${precoEfetivo.toStringAsFixed(2)}'),
              const Divider(height: 20),
              _dialogRow(
                'Subtotal:',
                'MZN ${totalParcial.toStringAsFixed(2)}',
                bold: true,
              ),
              const SizedBox(height: 12),

              // ── Nota informativa ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: adicionando ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: adicionando
                        ? Colors.green[200]!
                        : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      adicionando
                          ? Icons.add_shopping_cart
                          : Icons.info_outline,
                      color: adicionando ? Colors.green : Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        adicionando
                            ? 'Este item será adicionado ao pedido ${pedidoAtivo.reference}.'
                            : 'O pedido ficará em "Por Finalizar" aguardando confirmação.',
                        style: TextStyle(
                          fontSize: 12,
                          color: adicionando
                              ? Colors.green[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    adicionando ? Colors.green[700] : Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(adicionando ? 'Adicionar' : 'Confirmar'),
            ),
          ],
        ),
      ) ??
      false;
}

  Widget _dialogRow(String label, String valor, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(valor,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14,
              )),
        ],
      ),
    );
  }

  void _mostrarSnack(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderProduto(),
                  const SizedBox(height: 16),
                  _buildPrecoCard(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  if (produto.descricao != null &&
                      produto.descricao!.isNotEmpty)
                    _buildDescricaoCard(),
                  const SizedBox(height: 16),
                  _buildEstoqueCard(),
                  const SizedBox(height: 24),
                  _buildSelectorQuantidade(),
                  const SizedBox(height: 24),
                  _buildBotaoPedido(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace:
          FlexibleSpaceBar(background: _buildImagemHero()),
    );
  }

  Widget _buildImagemHero() {
    if (produto.imagemPrincipalUrl == null ||
        produto.imagemPrincipalUrl!.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Sem imagem',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return Image.network(
      '${ApiConfig.baseUrl}${produto.imagemPrincipalUrl}',
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
            color: Colors.grey[200],
            child:
                const Center(child: CircularProgressIndicator()));
      },
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey[200],
        child: Icon(Icons.broken_image,
            size: 64, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildHeaderProduto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (temPromocao)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('🏷️ PROMOÇÃO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
        Text(produto.nomeProduto,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                height: 1.3)),
      ],
    );
  }

  Widget _buildPrecoCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Preço',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              if (temPromocao)
                Text('MZN ${produto.preco.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                        fontSize: 14)),
              Text('MZN ${precoEfetivo.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: temPromocao
                          ? Colors.red[600]
                          : Colors.green[700])),
            ]),
            if (temPromocao) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.local_offer,
                    color: Colors.red[600], size: 24),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informações',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),
            _infoRow(Icons.label_outline, 'Marca', nomesMarcas),
            const Divider(height: 16),
            _infoRow(Icons.category_outlined, 'Categoria',
                nomesCategorias),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String valor) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey[500]),
      const SizedBox(width: 10),
      Text('$label:',
          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(valor,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.end)),
    ]);
  }

  Widget _buildDescricaoCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Descrição',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 10),
            Text(produto.descricao!,
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEstoqueCard() {
    final estoque = produto.quantidadeEstoque;
    final Color cor;
    final IconData icon;
    final String texto;

    if (estoque == 0) {
      cor = Colors.red;
      icon = Icons.remove_circle_outline;
      texto = 'Produto sem estoque';
    } else if (estoque <= 5) {
      cor = Colors.orange;
      icon = Icons.warning_amber_outlined;
      texto =
          'Apenas $estoque unidade${estoque > 1 ? 's' : ''} disponível${estoque > 1 ? 'is' : ''}';
    } else {
      cor = Colors.green;
      icon = Icons.inventory_2_outlined;
      texto = '$estoque unidades disponíveis em estoque';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: cor, size: 20),
        const SizedBox(width: 10),
        Text(texto,
            style: TextStyle(
                color: cor,
                fontWeight: FontWeight.w500,
                fontSize: 14)),
      ]),
    );
  }

  Widget _buildSelectorQuantidade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantidade',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        Row(children: [
          _botaoQuantidade(
              icon: Icons.remove,
              onTap: _diminuirQuantidade,
              enabled: _quantidade > 1),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: TextFormField(
                  key: ValueKey(_quantidade),
                  initialValue: _quantidade.toString(),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                  onChanged: (v) {
                    final num = int.tryParse(v);
                    if (num != null) _definirQuantidade(num);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _botaoQuantidade(
              icon: Icons.add,
              onTap: _aumentarQuantidade,
              enabled: _quantidade < produto.quantidadeEstoque),
        ]),
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total estimado:',
                  style: TextStyle(
                      color: Colors.grey[700], fontSize: 14)),
              Text('MZN ${totalParcial.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botaoQuantidade({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Material(
      color: enabled ? const Color(0xFF1A1A2E) : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon,
              color: enabled ? Colors.white : Colors.grey[400],
              size: 22),
        ),
      ),
    );
  }

Widget _buildBotaoPedido() {
  final semEstoque = produto.quantidadeEstoque == 0;

  // Reactivo ao pedido activo — reconstrói quando muda
  return ValueListenableBuilder<Pedido?>(
    valueListenable: PedidoAtivoController.instance.pedidoAtivo,
    builder: (context, pedidoAtivo, _) {
      final adicionando = pedidoAtivo != null;
      final label = _isCriandoPedido
          ? (adicionando ? 'A adicionar...' : 'A criar pedido...')
          : semEstoque
              ? 'Produto Indisponível'
              : adicionando
                  ? 'Adicionar ao ${pedidoAtivo.reference}'
                  : 'Criar Pedido';

      final icone = _isCriandoPedido
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(semEstoque
              ? Icons.block
              : adicionando
                  ? Icons.add_shopping_cart
                  : Icons.shopping_cart_checkout);

      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: semEstoque || _isCriandoPedido ? null : _criarPedido,
          icon: icone,
          label: Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: semEstoque
                ? Colors.grey
                : adicionando
                    ? Colors.green[700]
                    : Colors.green[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: semEstoque ? 0 : 2,
          ),
        ),
      );
    },
  );
}
}