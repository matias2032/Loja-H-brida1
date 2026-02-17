import 'package:flutter/material.dart';
import '../models/produto_model.dart';
import '../models/marca_model.dart';
import '../models/categoria_model.dart';
import '../services/produto_service.dart';
import '../services/marca_service.dart';
import '../services/categoria_service.dart';
import '../config/api_config.dart';
import 'detalhes_produto.dart';

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

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _searchController.addListener(_aplicarFiltros);
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
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Menu',
        style: TextStyle(
          color: Color(0xFF1A1A2E),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: [
        // Badge de filtros activos
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
              onPressed: () =>
                  setState(() => _filtrosVisiveis = !_filtrosVisiveis),
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
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
    final estoqueAbaixo = produto.quantidadeEstoque <= 5 && !semEstoque;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
    // DEPOIS:
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
        // Recarrega se pedido foi criado (DetalhesProduto faz pop(true))
        if (resultado == true) {
          await _carregarDados();
        }
      },
        child: Opacity(
          opacity: semEstoque ? 0.55 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildProdutoImagem(produto),
                ),
                const SizedBox(width: 12),

                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.nomeProduto,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.label_outline,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _obterNomesMarcas(produto.marcas),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.category_outlined,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _obterNomesCategorias(produto.categorias),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Preço
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (produto.precoPromocional != null)
                                Text(
                                  'MZN ${produto.preco.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                'MZN ${precoEfetivo.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: produto.precoPromocional != null
                                      ? Colors.red[600]
                                      : Colors.green[700],
                                ),
                              ),
                            ],
                          ),

                          // Badge de estoque
                          _buildEstoqueBadge(produto),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                if (!semEstoque)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 4),
                    child: Icon(Icons.chevron_right,
                        color: Colors.grey, size: 20),
                  ),
              ],
            ),
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
      label = 'Estoque: ${produto.quantidadeEstoque}';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 80,
          height: 80,
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
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported,
          size: 30, color: Colors.grey[400]),
    );
  }
}