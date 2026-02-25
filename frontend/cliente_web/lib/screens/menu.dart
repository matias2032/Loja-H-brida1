import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_config.dart';
import 'detalhes_produto.dart';
import '../controllers/pedido_ativo_controller.dart';
import '../widgets/pedido_ativo_banner.dart';
import  '../widgets/app_sidebar.dart';
import '../widgets/estoque_alerta_popup.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ProdutoService _produtoService = ProdutoService();
  final MarcaService _marcaService = MarcaService();
  final CategoriaService _categoriaService = CategoriaService();

  List<Produto> _produtos = [];
  List<Produto> _produtosFiltrados = [];
  List<Marca> _marcas = [];
  List<Categoria> _categorias = [];

  // Filtros
  int? _categoriaSelecionada;
  int? _marcaSelecionada;
  double? _precoMinimo;
  double? _precoMaximo;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _precoMinController = TextEditingController();
  final TextEditingController _precoMaxController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  bool _filtrosVisiveis = false;
final CarrinhoContadorService _carrinhoContador = CarrinhoContadorService.instance;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _searchController.addListener(_aplicarFiltros);
    PedidoAtivoController.instance.carregar(1);
   // Invalida cache para forçar leitura fresca ao entrar no ecrã
  _carrinhoContador.invalidarCache();
  _carrinhoContador.recarregarSeNecessario();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _precoMinController.dispose();
    _precoMaxController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final produtos = await _produtoService.listarProdutos();
      final marcas = await _marcaService.listarMarcasComCategorias();
      final categorias = await _categoriaService.listarCategorias();

      setState(() {
        // Filtrar apenas produtos activos e ordenar por quantidade (menor → maior)
        _produtos = produtos
            .where((p) => p.ativo == 1)
            .toList()
          ..sort((a, b) => a.quantidadeEstoque.compareTo(b.quantidadeEstoque));

        _marcas = marcas;
        _categorias = categorias;
        _isLoading = false;
      });

      _aplicarFiltros();
 _carrinhoContador.invalidarCache();
  _carrinhoContador.recarregarSeNecessario();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    List<Produto> resultado = List.from(_produtos);

    // Filtro por nome
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado
          .where((p) => p.nomeProduto.toLowerCase().contains(query))
          .toList();
    }

    // Filtro por categoria
    if (_categoriaSelecionada != null) {
      resultado = resultado
          .where((p) => p.categorias.contains(_categoriaSelecionada))
          .toList();
    }

    // Filtro por marca
    if (_marcaSelecionada != null) {
      resultado = resultado
          .where((p) => p.marcas.contains(_marcaSelecionada))
          .toList();
    }

    // Filtro por preço mínimo
    if (_precoMinimo != null) {
      resultado = resultado
          .where((p) =>
              (p.precoPromocional ?? p.preco) >= _precoMinimo!)
          .toList();
    }

    // Filtro por preço máximo
    if (_precoMaximo != null) {
      resultado = resultado
          .where((p) =>
              (p.precoPromocional ?? p.preco) <= _precoMaximo!)
          .toList();
    }

    setState(() {
      _produtosFiltrados = resultado;
    });
  }

  void _limparFiltros() {
    setState(() {
      _categoriaSelecionada = null;
      _marcaSelecionada = null;
      _precoMinimo = null;
      _precoMaximo = null;
      _searchController.clear();
      _precoMinController.clear();
      _precoMaxController.clear();
    });
    _aplicarFiltros();
  }

  bool get _temFiltrosActivos =>
      _categoriaSelecionada != null ||
      _marcaSelecionada != null ||
      _precoMinimo != null ||
      _precoMaximo != null ||
      _searchController.text.isNotEmpty;

  String _obterNomesMarcas(List<int> idsMarcas) {
    if (idsMarcas.isEmpty) return 'Sem marca';
    final nomes = idsMarcas
        .map((id) => _marcas
            .firstWhere(
              (m) => m.idMarca == id,
              orElse: () => Marca(idMarca: id, nomeMarca: 'Desconhecida'),
            )
            .nomeMarca)
        .join(', ');
    return nomes.isEmpty ? 'Sem marca' : nomes;
  }

  String _obterNomesCategorias(List<int> idsCategorias) {
    if (idsCategorias.isEmpty) return 'Sem categoria';
    final nomes = idsCategorias
        .map((id) => _categorias
            .firstWhere(
              (c) => c.idCategoria == id,
              orElse: () =>
                  Categoria(idCategoria: id, nomeCategoria: 'Desconhecida'),
            )
            .nomeCategoria)
        .join(', ');
    return nomes.isEmpty ? 'Sem categoria' : nomes;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF8F9FA),
    // Sidebar integrada corretamente
    drawer: const AppSidebar(currentRoute: '/menu'),
    appBar: _buildAppBar(),
    body: Stack(
      children: [
        _buildBody(),
        PedidoAtivoBanner(
          onDesativado: _carregarDados,
           // refresh após desativar
        ),
        const EstoqueAlertaPopup(),
      ],
    ),
  );
}
 PreferredSizeWidget _buildAppBar() {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    // Botão que abre a Sidebar (importante para integração)
    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF1A1A2E)),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),
    title: const Text(
      'Menu',
      style: TextStyle(
        color: Color(0xFF1A1A2E),
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
    ),
   actions: [

// Substituir todo o Stack do ícone de pedidos por:
StreamBuilder<int>(
  stream: _carrinhoContador.contadorStream,
  initialData: _carrinhoContador.contadorAtual,
  builder: (context, snapshot) {
    final contador = snapshot.data ?? 0;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1A1A2E)),
          tooltip: 'Carrinho',
          onPressed: () async {
            await Navigator.of(context).pushNamed('/carrinho');
            _carrinhoContador.invalidarCache();
            await _carrinhoContador.recarregarSeNecessario();
          },
        ),
        if (contador > 0)
          Positioned(
            right: 6, top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 4, spreadRadius: 1)],
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text('$contador',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  },
),

  // ── FILTROS (MANTIDO) ──
  Stack(
    alignment: Alignment.topRight,
    children: [
      IconButton(
        icon: Icon(
          _filtrosVisiveis ? Icons.filter_list_off : Icons.filter_list,
          color: _temFiltrosActivos
              ? Theme.of(context).primaryColor
              : const Color(0xFF1A1A2E),
        ),
        onPressed: () => setState(() => _filtrosVisiveis = !_filtrosVisiveis),
        tooltip: 'Filtros',
      ),
      if (_temFiltrosActivos)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
    ],
  ),

  // ── ATUALIZAR (MANTIDO) ──
  IconButton(
    icon: const Icon(Icons.refresh, color: Color(0xFF1A1A2E)),
    onPressed: _carregarDados,
    tooltip: 'Actualizar',
  ),
],
  );
}
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _carregarDados,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        if (_filtrosVisiveis) _buildPainelFiltros(),
        _buildResultadoInfo(),
        Expanded(
          child: _produtosFiltrados.isEmpty
              ? _buildEmptyState()
              : _buildListaProdutos(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Pesquisar produto...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _aplicarFiltros();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF0F0F0),
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

  Widget _buildPainelFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (_temFiltrosActivos)
                TextButton.icon(
                  onPressed: _limparFiltros,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Limpar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Categoria e Marca em linha
          Row(
            children: [
              Expanded(child: _buildDropdownCategoria()),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdownMarca()),
            ],
          ),
          const SizedBox(height: 12),

          // Preço mínimo e máximo
          Row(
            children: [
              Expanded(child: _buildCampoPreco(
                controller: _precoMinController,
                label: 'Preço mínimo',
                onChanged: (v) {
                  _precoMinimo = double.tryParse(v);
                  _aplicarFiltros();
                },
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildCampoPreco(
                controller: _precoMaxController,
                label: 'Preço máximo',
                onChanged: (v) {
                  _precoMaximo = double.tryParse(v);
                  _aplicarFiltros();
                },
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCategoria() {
    return DropdownButtonFormField<int>(
      value: _categoriaSelecionada,
      decoration: _dropdownDecoration('Categoria'),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Todas'),
        ),
        ..._categorias.map((c) => DropdownMenuItem<int>(
              value: c.idCategoria,
              child: Text(
                c.nomeCategoria,
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: (v) {
        setState(() => _categoriaSelecionada = v);
        _aplicarFiltros();
      },
    );
  }

  Widget _buildDropdownMarca() {
    return DropdownButtonFormField<int>(
      value: _marcaSelecionada,
      decoration: _dropdownDecoration('Marca'),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Todas'),
        ),
        ..._marcas.map((m) => DropdownMenuItem<int>(
              value: m.idMarca,
              child: Text(
                m.nomeMarca,
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: (v) {
        setState(() => _marcaSelecionada = v);
        _aplicarFiltros();
      },
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildCampoPreco({
    required TextEditingController controller,
    required String label,
    required void Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixText: 'MZN ',
        prefixStyle:
            const TextStyle(fontSize: 12, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildResultadoInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_produtosFiltrados.length} produto${_produtosFiltrados.length != 1 ? 's' : ''} encontrado${_produtosFiltrados.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Icon(Icons.sort, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            'Menor estoque primeiro',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _temFiltrosActivos
                ? Icons.search_off
                : Icons.inventory_2_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _temFiltrosActivos
                ? 'Nenhum produto corresponde\naos filtros aplicados'
                : 'Nenhum produto disponível',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          if (_temFiltrosActivos) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _limparFiltros,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpar filtros'),
            ),
          ],
        ],
      ),
    );
  }

Widget _buildListaProdutos() {
    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 cartões por linha
          childAspectRatio: 0.82, // Proporção ajustada (largura/altura). Se achar muito alto, aumente para 0.85
          crossAxisSpacing: 16, // Espaço horizontal
          mainAxisSpacing: 16, // Espaço vertical
        ),
        itemCount: _produtosFiltrados.length,
        itemBuilder: (context, index) {
          return _buildProdutoCard(_produtosFiltrados[index]);
        },
      ),
    );
  }

Widget _buildProdutoCard(Produto produto) {
    final precoEfetivo = produto.precoPromocional ?? produto.preco;
    final semEstoque = produto.quantidadeEstoque == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Borda um pouco mais suave
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: semEstoque
            ? null
            : () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalhesProdutoScreen(
                      produto: produto,
                      marcas: _marcas,
                      categorias: _categorias,
                    ),
                  ),
                );
                if (resultado is Pedido) {
                  PedidoAtivoController.instance.definir(resultado);
                  await _carregarDados();
                } else if (resultado == true) {
                  await _carregarDados();
                }
              },
        child: Opacity(
          opacity: semEstoque ? 0.55 : 1.0,
          child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    // 1. Imagem
    Expanded(
      child: SizedBox(
        width: double.infinity,
        child: _buildProdutoImagem(produto),
      ),
    ),
    
    // 2. Detalhes com Marca e Categoria
    Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10), // Aumentei levemente o padding lateral
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marca e Categoria (Texto secundário)
          Text(
            '${_obterNomesMarcas(produto.marcas)} • ${_obterNomesCategorias(produto.categorias)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400], // Cor suave para não brigar com o nome
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4), // Espaço entre categoria e nome
          
          // Nome do Produto
          Text(
            produto.nomeProduto,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 6), // Espaço para o preço respirar
          
          // Preço
          Text(
            'MZN ${precoEfetivo.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.greenAccent[400],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Badge de Estoque
          _buildEstoqueBadge(produto),
        ],
      ),
    ),
  ],
),
        ),
      ),
    );
  }

Widget _buildEstoqueBadge(Produto produto) {
    Color bgColor, borderColor, textColor;
    String label;
    IconData icon;

    if (produto.quantidadeEstoque == 0) {
      bgColor = Colors.red[50]!;
      borderColor = Colors.red;
      textColor = Colors.red[700]!;
      label = 'Sem estoque';
      icon = Icons.remove_circle_outline;
    } else if (produto.quantidadeEstoque <= 5) {
      bgColor = Colors.orange[50]!;
      borderColor = Colors.orange;
      textColor = Colors.orange[700]!;
      label = 'Restam ${produto.quantidadeEstoque}';
      icon = Icons.warning_amber_outlined;
    } else {
      bgColor = Colors.green[50]!;
      borderColor = Colors.green;
      textColor = Colors.green[700]!;
      label = 'Estq: ${produto.quantidadeEstoque}'; // Abreviação para "Estoque"
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Padding menor
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor), // Ícone menor
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9, // Fonte bem pequena para garantir que cabe na largura
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildProdutoImagem(Produto produto) {
    if (produto.imagemPrincipalUrl == null ||
        produto.imagemPrincipalUrl!.isEmpty) {
      return _buildPlaceholderImage();
    }

    final urlCompleta = '${ApiConfig.baseUrl}${produto.imagemPrincipalUrl}';

    return Image.network(
      urlCompleta,
      fit: BoxFit.cover, // Garante que a imagem preencha todo o topo do cartão
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported,
          size: 40, color: Colors.grey[400]),
    );
  }
}