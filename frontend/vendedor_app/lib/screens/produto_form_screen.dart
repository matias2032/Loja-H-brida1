import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/produto_model.dart';
import '../models/marca_model.dart';
import '../models/categoria_model.dart';
import '../services/produto_service.dart';
import '../services/marca_service.dart';
import '../services/categoria_service.dart';

class ProdutoFormScreen extends StatefulWidget {
  final Produto? produto; // null = criar, preenchido = editar

  const ProdutoFormScreen({
    Key? key,
    this.produto,
  }) : super(key: key);

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProdutoService _produtoService = ProdutoService();
  final MarcaService _marcaService = MarcaService();
  final CategoriaService _categoriaService = CategoriaService();

  // Controllers
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _precoPromocionalController;
  late TextEditingController _estoqueController;

  // Listas completas
  List<Marca> _todasMarcas = [];
  List<Categoria> _todasCategorias = [];

  // Listas filtradas (baseadas na seleção)
  List<Marca> _marcasFiltradas = [];
  List<Categoria> _categoriasFiltradas = [];

  // Seleções
  List<int> _marcasSelecionadas = [];
  List<int> _categoriasSelecionadas = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _carregarDados();
  }

  void _initControllers() {
    _nomeController = TextEditingController(text: widget.produto?.nomeProduto ?? '');
    _descricaoController = TextEditingController(text: widget.produto?.descricao ?? '');
    _precoController = TextEditingController(
      text: widget.produto?.preco.toStringAsFixed(2) ?? '',
    );
    _precoPromocionalController = TextEditingController(
      text: widget.produto?.precoPromocional?.toStringAsFixed(2) ?? '',
    );
    _estoqueController = TextEditingController(
      text: widget.produto?.quantidadeEstoque.toString() ?? '0',
    );

    // Carregar seleções existentes
    if (widget.produto != null) {
      _marcasSelecionadas = List.from(widget.produto!.marcas);
      _categoriasSelecionadas = List.from(widget.produto!.categorias);
    }
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final marcasComCategorias = await _marcaService.listarMarcasComCategorias();
      final categorias = await _categoriaService.listarCategorias();

      setState(() {
        _todasMarcas = marcasComCategorias;
        _todasCategorias = categorias;
        
        // Inicialmente mostrar todas
        _marcasFiltradas = List.from(_todasMarcas);
        _categoriasFiltradas = List.from(_todasCategorias);
        
        _isLoading = false;
      });

      // Se estiver editando, aplicar filtros com base nas seleções existentes
      if (widget.produto != null) {
        _aplicarFiltros();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarErro('Erro ao carregar dados: $e');
    }
  }

  // ===== LÓGICA DE FILTRO INTERLIGADO =====

  void _aplicarFiltros() {
    setState(() {
      if (_marcasSelecionadas.isEmpty && _categoriasSelecionadas.isEmpty) {
        // Nenhuma seleção: mostrar tudo
        _marcasFiltradas = List.from(_todasMarcas);
        _categoriasFiltradas = List.from(_todasCategorias);
      } else if (_marcasSelecionadas.isNotEmpty && _categoriasSelecionadas.isEmpty) {
        // Marcas selecionadas: filtrar categorias
        _filtrarCategoriasPorMarcas();
        _marcasFiltradas = List.from(_todasMarcas);
      } else if (_categoriasSelecionadas.isNotEmpty && _marcasSelecionadas.isEmpty) {
        // Categorias selecionadas: filtrar marcas
        _filtrarMarcasPorCategorias();
        _categoriasFiltradas = List.from(_todasCategorias);
      } else {
        // Ambos selecionados: mostrar compatíveis
        _filtrarCategoriasPorMarcas();
        _filtrarMarcasPorCategorias();
      }
    });
  }

  void _filtrarCategoriasPorMarcas() {
    final categoriasValidas = <int>{};
    
    for (final idMarca in _marcasSelecionadas) {
      final marca = _todasMarcas.firstWhere(
        (m) => m.idMarca == idMarca,
        orElse: () => Marca(nomeMarca: ''),
      );
      
      if (marca.categorias != null) {
        categoriasValidas.addAll(
          marca.categorias!.map((c) => c.idCategoria!),
        );
      }
    }

    _categoriasFiltradas = _todasCategorias
        .where((c) => categoriasValidas.contains(c.idCategoria))
        .toList();
  }

  void _filtrarMarcasPorCategorias() {
    final marcasValidas = <int>{};
    
    for (final marca in _todasMarcas) {
      if (marca.categorias != null) {
        final temCategoriaValida = marca.categorias!.any(
          (c) => _categoriasSelecionadas.contains(c.idCategoria),
        );
        if (temCategoriaValida) {
          marcasValidas.add(marca.idMarca!);
        }
      }
    }

    _marcasFiltradas = _todasMarcas
        .where((m) => marcasValidas.contains(m.idMarca))
        .toList();
  }

void _onMarcaSelecionada(int? idMarca, bool selecionado) {
  if (idMarca == null) return;

  setState(() {
    if (selecionado) {
      if (_marcasSelecionadas.isNotEmpty) return; // 🔒 Bloqueia múltiplas seleções
      _marcasSelecionadas = [idMarca];
    } else {
      _marcasSelecionadas.clear();
    }

    _aplicarFiltros();
  });
}

void _onCategoriaSelecionada(int? idCategoria, bool selecionado) {
  if (idCategoria == null) return;

  setState(() {
    if (selecionado) {
      if (_categoriasSelecionadas.isNotEmpty) return; // 🔒 Bloqueia múltiplas seleções
      _categoriasSelecionadas = [idCategoria];
    } else {
      _categoriasSelecionadas.clear();
    }

    _aplicarFiltros();
  });
}


  // ===== SALVAR PRODUTO =====

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_marcasSelecionadas.isEmpty) {
      _mostrarErro('Selecione pelo menos uma marca');
      return;
    }

    if (_categoriasSelecionadas.isEmpty) {
      _mostrarErro('Selecione pelo menos uma categoria');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final produto = Produto(
        idProduto: widget.produto?.idProduto,
        nomeProduto: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        preco: double.parse(_precoController.text.replaceAll(',', '.')),
        quantidadeEstoque: int.parse(_estoqueController.text),
        precoPromocional: _precoPromocionalController.text.isNotEmpty
            ? double.parse(_precoPromocionalController.text.replaceAll(',', '.'))
            : null,
        categorias: _categoriasSelecionadas,
        marcas: _marcasSelecionadas,
      );

      if (widget.produto == null) {
        await _produtoService.criarProduto(produto);
        _mostrarSucesso('Produto criado com sucesso');
      } else {
        await _produtoService.atualizarProduto(widget.produto!.idProduto!, produto);
        _mostrarSucesso('Produto atualizado com sucesso');
      }

      Navigator.pop(context, true);
    } catch (e) {
      _mostrarErro('Erro ao salvar: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produto == null ? 'Novo Produto' : 'Editar Produto'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCampoTexto(
                      controller: _nomeController,
                      label: 'Nome do Produto *',
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildCampoTexto(
                      controller: _descricaoController,
                      label: 'Descrição',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCampoNumerico(
                            controller: _precoController,
                            label: 'Preço *',
                            prefixo: 'R\$ ',
                            validator: (v) {
                              if (v!.isEmpty) return 'Campo obrigatório';
                              if (double.tryParse(v.replaceAll(',', '.')) == null) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCampoNumerico(
                            controller: _precoPromocionalController,
                            label: 'Preço Promocional',
                            prefixo: 'R\$ ',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCampoNumerico(
                      controller: _estoqueController,
                      label: 'Quantidade em Estoque *',
                      soInteiros: true,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Marcas e Categorias *',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecione marcas ou categorias. As opções serão filtradas automaticamente.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildSecaoMarcas(),
                    const SizedBox(height: 16),
                    _buildSecaoCategorias(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.produto == null ? 'CRIAR PRODUTO' : 'SALVAR ALTERAÇÕES',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String label,
    String? prefixo,
    bool soInteiros = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: prefixo,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: !soInteiros),
      inputFormatters: [
        if (soInteiros) FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
    );
  }

  Widget _buildSecaoMarcas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Marcas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_marcasFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Nenhuma marca disponível para as categorias selecionadas',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Wrap(
                spacing: 8,
                children: _marcasFiltradas.map((marca) {
                  final selecionada = _marcasSelecionadas.contains(marca.idMarca);
              return FilterChip(
  label: Text(marca.nomeMarca),
  selected: selecionada,
  onSelected: selecionada || _marcasSelecionadas.isEmpty
      ? (selected) => _onMarcaSelecionada(marca.idMarca, selected)
      : null, // 🔒 Bloqueia outras
);

                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoCategorias() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categorias',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_categoriasFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Nenhuma categoria disponível para as marcas selecionadas',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Wrap(
                spacing: 8,
                children: _categoriasFiltradas.map((categoria) {
                  final selecionada = _categoriasSelecionadas.contains(categoria.idCategoria);
           return FilterChip(
  label: Text(categoria.nomeCategoria),
  selected: selecionada,
  onSelected: selecionada || _categoriasSelecionadas.isEmpty
      ? (selected) => _onCategoriaSelecionada(categoria.idCategoria, selected)
      : null, // 🔒 Bloqueia outras
);

                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.green),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _precoPromocionalController.dispose();
    _estoqueController.dispose();
    super.dispose();
  }
}