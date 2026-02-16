import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/produto_model.dart';
import '../models/marca_model.dart';
import '../models/categoria_model.dart';
import '../services/produto_service.dart';
import '../services/marca_service.dart';
import '../services/categoria_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/produto_imagem_model.dart';
import '../config/api_config.dart';
import 'dart:ui';
import 'package:cross_file/cross_file.dart';  
import 'package:desktop_drop/desktop_drop.dart';  // ✅ NOVO
  

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
// Variáveis para imagens
List<ProdutoImagem> _imagensExistentes = [];
List<File> _novasImagens = [];
final ImagePicker _picker = ImagePicker();
bool _isLoadingImagens = false;
bool _isDragging = false; 

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
   
if (widget.produto?.idProduto != null) {
  _carregarImagensExistentes();
}
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
      _isLoading = false;
    });

    // ✅ NOVO: Aplicar filtros APÓS carregar os dados
    _inicializarFiltros();
    
  } catch (e) {
    setState(() => _isLoading = false);
    _mostrarErro('Erro ao carregar dados: $e');
  }
}



// ✅ NOVO MÉTODO: Inicializa os filtros corretamente
void _inicializarFiltros() {
  if (widget.produto != null) {
    // Modo edição: aplicar filtros baseados nas seleções existentes
    print('📝 Modo edição - Marcas: $_marcasSelecionadas, Categorias: $_categoriasSelecionadas');
    _aplicarFiltros();
  } else {
    // Modo criação: mostrar tudo
    setState(() {
      _marcasFiltradas = List.from(_todasMarcas);
      _categoriasFiltradas = List.from(_todasCategorias);
    });
  }
}

  // ===== LÓGICA DE FILTRO INTERLIGADO =====

  void _aplicarFiltros() {
  setState(() {
    if (_marcasSelecionadas.isEmpty && _categoriasSelecionadas.isEmpty) {
      // Nenhuma seleção: mostrar tudo
      _marcasFiltradas = List.from(_todasMarcas);
      _categoriasFiltradas = List.from(_todasCategorias);
      print('🔄 Filtros: Mostrando tudo (nenhuma seleção)');
    } else if (_marcasSelecionadas.isNotEmpty && _categoriasSelecionadas.isEmpty) {
      // Marcas selecionadas: filtrar categorias
      _filtrarCategoriasPorMarcas();
      _marcasFiltradas = List.from(_todasMarcas);
      print('🔄 Filtros: ${_marcasSelecionadas.length} marca(s) selecionada(s), filtrando categorias');
      print('   Categorias disponíveis: ${_categoriasFiltradas.length}');
    } else if (_categoriasSelecionadas.isNotEmpty && _marcasSelecionadas.isEmpty) {
      // Categorias selecionadas: filtrar marcas
      _filtrarMarcasPorCategorias();
      _categoriasFiltradas = List.from(_todasCategorias);
      print('🔄 Filtros: ${_categoriasSelecionadas.length} categoria(s) selecionada(s), filtrando marcas');
      print('   Marcas disponíveis: ${_marcasFiltradas.length}');
    } else {
      // Ambos selecionados: mostrar compatíveis
      _filtrarCategoriasPorMarcas();
      _filtrarMarcasPorCategorias();
      print('🔄 Filtros: Marca e categoria selecionadas');
      print('   Marcas compatíveis: ${_marcasFiltradas.length}');
      print('   Categorias compatíveis: ${_categoriasFiltradas.length}');
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
  
  print('   ✅ Categorias válidas para as marcas selecionadas: ${categoriasValidas.length}');
}



Future<void> _processarArquivosArrastados(List<XFile> files) async {
  final imagensValidas = <File>[];
  
  for (final file in files) {
    // Verificar se é uma imagem
    final extensao = file.path.toLowerCase();
    if (extensao.endsWith('.jpg') || 
        extensao.endsWith('.jpeg') || 
        extensao.endsWith('.png') || 
        extensao.endsWith('.gif') ||
        extensao.endsWith('.webp') ||
        extensao.endsWith('.jfif')) {
      imagensValidas.add(File(file.path));
    }
  }
  
  if (imagensValidas.isEmpty) {
    _mostrarErro('Nenhuma imagem válida encontrada. Use JPG, PNG, GIF, JFIF ou WEBP.');
    return;
  }
  
  setState(() {
    _novasImagens.addAll(imagensValidas);
  });
  
  _mostrarSucesso('${imagensValidas.length} imagem(ns) adicionada(s)');
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
  
  print('   ✅ Marcas válidas para as categorias selecionadas: ${marcasValidas.length}');
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

  // MODIFICAR o método _salvar() para incluir upload de imagens:
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

    Produto produtoSalvo;
    if (widget.produto == null) {
      produtoSalvo = await _produtoService.criarProduto(produto);
      _mostrarSucesso('Produto criado com sucesso');
    } else {
      produtoSalvo = await _produtoService.atualizarProduto(
        widget.produto!.idProduto!,
        produto,
      );
      _mostrarSucesso('Produto atualizado com sucesso');
    }

    // ✅ UPLOAD DAS NOVAS IMAGENS
    if (_novasImagens.isNotEmpty && produtoSalvo.idProduto != null) {
      for (int i = 0; i < _novasImagens.length; i++) {
        await _produtoService.adicionarImagem(
          idProduto: produtoSalvo.idProduto!,
          imagemFile: _novasImagens[i],
          legenda: null,
          imagemPrincipal: i == 0 && _imagensExistentes.isEmpty, // Primeira imagem = principal
        );
      }
      _mostrarSucesso('${_novasImagens.length} imagem(ns) adicionada(s)');
    }

    Navigator.pop(context, true);
  } catch (e) {
    _mostrarErro('Erro ao salvar: $e');
  } finally {
    setState(() => _isSaving = false);
  }
}
// ADICIONE este método:
Future<void> _carregarImagensExistentes() async {
  if (widget.produto?.idProduto == null) return;
  
  setState(() => _isLoadingImagens = true);
  try {
    final imagens = await _produtoService.listarImagensDoProduto(
      widget.produto!.idProduto!,
    );
    setState(() {
      _imagensExistentes = imagens;
      _isLoadingImagens = false;
    });
  } catch (e) {
    setState(() => _isLoadingImagens = false);
    print('Erro ao carregar imagens: $e');
  }
}

// ADICIONE estes métodos:
Future<void> _selecionarImagem() async {
  try {
    final XFile? imagem = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (imagem != null) {
      setState(() {
        _novasImagens.add(File(imagem.path));
      });
    }
  } catch (e) {
    _mostrarErro('Erro ao selecionar imagem: $e');
  }
}

Future<void> _tirarFoto() async {
  try {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (foto != null) {
      setState(() {
        _novasImagens.add(File(foto.path));
      });
    }
  } catch (e) {
    _mostrarErro('Erro ao tirar foto: $e');
  }
}

void _removerNovaImagem(int index) {
  setState(() {
    _novasImagens.removeAt(index);
  });
}

Future<void> _removerImagemExistente(ProdutoImagem imagem) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar'),
      content: const Text('Deseja realmente remover esta imagem?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remover', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmar == true && imagem.idImagem != null) {
    try {
      await _produtoService.removerImagem(imagem.idImagem!);
      setState(() {
        _imagensExistentes.removeWhere((img) => img.idImagem == imagem.idImagem);
      });
      _mostrarSucesso('Imagem removida');
    } catch (e) {
      _mostrarErro('Erro ao remover imagem: $e');
    }
  }
}

Future<void> _definirImagemPrincipal(ProdutoImagem imagem) async {
  if (widget.produto?.idProduto == null || imagem.idImagem == null) return;

  try {
    await _produtoService.definirImagemPrincipal(
      widget.produto!.idProduto!,
      imagem.idImagem!,
    );
    await _carregarImagensExistentes();
    _mostrarSucesso('Imagem principal definida');
  } catch (e) {
    _mostrarErro('Erro ao definir imagem principal: $e');
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
                    const SizedBox(height: 24),
                  _buildSecaoImagens(),
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

Widget _buildSecaoImagens() {
  return DropTarget(
    onDragDone: (details) async {
      setState(() => _isDragging = false);
      await _processarArquivosArrastados(details.files);
    },
    onDragEntered: (details) {
      setState(() => _isDragging = true);
    },
    onDragExited: (details) {
      setState(() => _isDragging = false);
    },
    child: Card(
      elevation: _isDragging ? 8 : 2,
      color: _isDragging ? Colors.blue[50] : null,
      child: Container(
        decoration: _isDragging
            ? BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Imagens do Produto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _tirarFoto,
                        tooltip: 'Tirar foto',
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library),
                        onPressed: _selecionarImagem,
                        tooltip: 'Escolher da galeria',
                      ),
                    ],
                  ),
                ],
              ),
              
              // ✅ NOVO: Banner de instrução
              if (!_isDragging) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.upload_file, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Arraste imagens do explorador de arquivos para cá',
                          style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // ✅ NOVO: Overlay de drag ativo
              if (_isDragging) ...[
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 2, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 48, color: Colors.blue[700]),
                        const SizedBox(height: 8),
                        Text(
                          'Solte as imagens aqui',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Imagens existentes
              if (_isLoadingImagens)
                const Center(child: CircularProgressIndicator())
              else if (_imagensExistentes.isNotEmpty) ...[
                const Text('Imagens salvas:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagensExistentes.length,
                    itemBuilder: (context, index) {
                      final imagem = _imagensExistentes[index];
                      return _buildImagemExistente(imagem);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Novas imagens (ainda não salvas)
              if (_novasImagens.isNotEmpty) ...[
                const Text('Novas imagens:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _novasImagens.length,
                    itemBuilder: (context, index) {
                      return _buildNovaImagem(_novasImagens[index], index);
                    },
                  ),
                ),
              ],
              
              if (_imagensExistentes.isEmpty && _novasImagens.isEmpty && !_isDragging)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhuma imagem adicionada',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Arraste imagens ou clique nos botões acima',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildImagemExistente(ProdutoImagem imagem) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    width: 120,
    decoration: BoxDecoration(
      border: Border.all(
        color: imagem.imagemPrincipal == 1 ? Colors.blue : Colors.grey[300]!,
        width: imagem.imagemPrincipal == 1 ? 3 : 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            '${ApiConfig.baseUrl}${imagem.caminhoImagem}',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48),
              );
            },
          ),
        ),
        if (imagem.imagemPrincipal == 1)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRINCIPAL',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              if (imagem.imagemPrincipal != 1)
                PopupMenuItem(
                  child: const Text('Definir como principal'),
                  onTap: () => Future.delayed(
                    Duration.zero,
                    () => _definirImagemPrincipal(imagem),
                  ),
                ),
              PopupMenuItem(
                child: const Text('Remover', style: TextStyle(color: Colors.red)),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _removerImagemExistente(imagem),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildNovaImagem(File imagem, int index) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    width: 120,
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            imagem,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        if (index == 0 && _imagensExistentes.isEmpty)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NOVA PRINCIPAL',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _removerNovaImagem(index),
          ),
        ),
      ],
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