import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_config.dart';
import 'produto_form_screen.dart';
import '../widgets/app_sidebar.dart'; // ✅ ADICIONE este import
import 'package:api_compartilhado/api_compartilhado.dart';


class ProdutoListScreen extends StatefulWidget {
  const ProdutoListScreen({Key? key}) : super(key: key);

  @override
  State<ProdutoListScreen> createState() => _ProdutoListScreenState();
}

class _ProdutoListScreenState extends State<ProdutoListScreen> {
  final ProdutoService _produtoService = ProdutoService();
  final MarcaService _marcaService = MarcaService();
  final CategoriaService _categoriaService = CategoriaService();

  List<Produto> _produtos = [];
  List<Marca> _marcas = [];
  List<Categoria> _categorias = [];
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarDados();
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
        _produtos = produtos;
        _marcas = marcas;
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _obterNomesMarcas(List<int> idsMarcas) {
    if (idsMarcas.isEmpty) return 'Sem marca';
    
    final nomes = idsMarcas
        .map((id) => _marcas.firstWhere(
              (m) => m.idMarca == id,
              orElse: () => Marca(idMarca: id, nomeMarca: 'Desconhecida'),
            ).nomeMarca)
        .join(', ');
    
    return nomes.isEmpty ? 'Sem marca' : nomes;
  }

  String _obterNomesCategorias(List<int> idsCategorias) {
    if (idsCategorias.isEmpty) return 'Sem categoria';
    
    final nomes = idsCategorias
        .map((id) => _categorias.firstWhere(
              (c) => c.idCategoria == id,
              orElse: () => Categoria(idCategoria: id, nomeCategoria: 'Desconhecida'),
            ).nomeCategoria)
        .join(', ');
    
    return nomes.isEmpty ? 'Sem categoria' : nomes;
  }

  Future<void> _toggleAtivo(Produto produto) async {
    try {
      await _produtoService.toggleAtivo(produto.idProduto!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            produto.ativo == 1 
                ? 'Produto desativado com sucesso' 
                : 'Produto ativado com sucesso',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _carregarDados();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),

      drawer: const AppSidebar(currentRoute: '/produtos'),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProdutoFormScreen(),
            ),
          );
          if (result == true) _carregarDados();
        },
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDados,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_produtos.isEmpty) {
      return const Center(
        child: Text('Nenhum produto cadastrado'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _produtos.length,
      itemBuilder: (context, index) {
        final produto = _produtos[index];
        return _buildProdutoCard(produto);
      },
    );
  }

  Widget _buildProdutoCard(Produto produto) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProdutoFormScreen(
                produto: produto,
              ),
            ),
          );
          if (result == true) _carregarDados();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ IMAGEM DO PRODUTO - ATUALIZADA
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildProdutoImagem(produto),
              ),
              const SizedBox(width: 12),
              
              // Informações do produto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nomeProduto,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.label, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _obterNomesMarcas(produto.marcas),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.category, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _obterNomesCategorias(produto.categorias),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (produto.precoPromocional != null) ...[
                              Text(
                                'MZN ${produto.preco.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'MZN ${produto.precoPromocional!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ] else
                              Text(
                                'MZN ${produto.preco.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: produto.quantidadeEstoque > 10 
                                ? Colors.green[50] 
                                : produto.quantidadeEstoque > 0 
                                    ? Colors.orange[50]
                                    : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: produto.quantidadeEstoque > 10 
                                  ? Colors.green 
                                  : produto.quantidadeEstoque > 0 
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          child: Text(
                            'Estoque: ${produto.quantidadeEstoque}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: produto.quantidadeEstoque > 10 
                                  ? Colors.green[700] 
                                  : produto.quantidadeEstoque > 0 
                                      ? Colors.orange[700]
                                      : Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Ações
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      produto.ativo == 1 ? Icons.toggle_on : Icons.toggle_off,
                      color: produto.ativo == 1 ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () => _toggleAtivo(produto),
                  ),
                  Text(
                    produto.ativo == 1 ? 'Ativo' : 'Inativo',
                    style: TextStyle(
                      fontSize: 10,
                      color: produto.ativo == 1 ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NOVO MÉTODO PARA CONSTRUIR A IMAGEM
  Widget _buildProdutoImagem(Produto produto) {
    // Se não tem imagem, mostrar placeholder
    if (produto.imagemPrincipalUrl == null || produto.imagemPrincipalUrl!.isEmpty) {
      return _buildPlaceholderImage();
    }

    // Construir URL completa
    final String urlCompleta = '${ApiConfig.baseUrl}${produto.imagemPrincipalUrl}';
    
    print('🖼️ Tentando carregar imagem: $urlCompleta'); // Debug

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
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Erro ao carregar imagem: $error'); // Debug
        return _buildPlaceholderImage();
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 32, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            'Sem imagem',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}