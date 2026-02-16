import 'package:flutter/material.dart';
import '../models/produto_model.dart';
import '../models/marca_model.dart';
import '../models/categoria_model.dart';
import '../services/produto_service.dart';
import '../services/marca_service.dart';
import '../services/categoria_service.dart';
import 'produto_form_screen.dart';

class ProdutoListScreen extends StatefulWidget {
  const ProdutoListScreen({Key? key}) : super(key: key);

  @override
  State<ProdutoListScreen> createState() => _ProdutoListScreenState();
}

class _ProdutoListScreenState extends State<ProdutoListScreen> {
  final ProdutoService _produtoService = ProdutoService();
  final MarcaService _marcaService = MarcaService();
  final CategoriaService _categoriaService = CategoriaService();

  List<Produto> _produtos = []; // ✅ MUDANÇA: ProdutoModel → Produto
  List<Marca> _marcas = []; // ✅ MUDANÇA: MarcaModel → Marca
  List<Categoria> _categorias = []; // ✅ MUDANÇA: CategoriaModel → Categoria
  
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
      final marcas = await _marcaService.listarMarcasComCategorias(); // ✅ MUDANÇA: usar método com categorias
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
              orElse: () => Marca(idMarca: id, nomeMarca: 'Desconhecida'), // ✅ MUDANÇA
            ).nomeMarca)
        .join(', ');
    
    return nomes.isEmpty ? 'Sem marca' : nomes;
  }

  String _obterNomesCategorias(List<int> idsCategorias) {
    if (idsCategorias.isEmpty) return 'Sem categoria';
    
    final nomes = idsCategorias
        .map((id) => _categorias.firstWhere(
              (c) => c.idCategoria == id,
              orElse: () => Categoria(idCategoria: id, nomeCategoria: 'Desconhecida'), // ✅ MUDANÇA
            ).nomeCategoria)
        .join(', ');
    
    return nomes.isEmpty ? 'Sem categoria' : nomes;
  }

  Future<void> _toggleAtivo(Produto produto) async { // ✅ MUDANÇA: ProdutoModel → Produto
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProdutoFormScreen(), // ✅ MUDANÇA: remover parâmetros (screen carrega os dados internamente)
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

  Widget _buildProdutoCard(Produto produto) { // ✅ MUDANÇA: ProdutoModel → Produto
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProdutoFormScreen(
                produto: produto, // ✅ MUDANÇA: só passar o produto
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
              // Imagem do produto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: produto.imagemPrincipalUrl != null
                    ? Image.network(
                        produto.imagemPrincipalUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
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
                        Text(
                          'R\$ ${produto.preco.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Estoque: ${produto.quantidadeEstoque}',
                          style: const TextStyle(fontSize: 12),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
    );
  }
}