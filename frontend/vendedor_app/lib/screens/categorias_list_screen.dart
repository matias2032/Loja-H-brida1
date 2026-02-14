// lib/screens/categoria/categorias_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/categoria_model.dart';
import '../../services/categoria_service.dart';
import 'categoria_form_screen.dart';

class CategoriasListScreen extends StatefulWidget {
  const CategoriasListScreen({Key? key}) : super(key: key);

  @override
  State<CategoriasListScreen> createState() => _CategoriasListScreenState();
}

class _CategoriasListScreenState extends State<CategoriasListScreen> {
  final CategoriaService _categoriaService = CategoriaService();
  List<Categoria> _categorias = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categorias = await _categoriaService.listarCategorias();
      setState(() {
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar categorias: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletarCategoria(Categoria categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir a categoria "${categoria.nomeCategoria}"?\n\n'
          '⚠️ As marcas e produtos associados NÃO serão excluídos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && categoria.idCategoria != null) {
      try {
        await _categoriaService.deletarCategoria(categoria.idCategoria!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Categoria "${categoria.nomeCategoria}" excluída'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarCategorias();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navegarParaFormulario({Categoria? categoria}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriaFormScreen(categoria: categoria),
      ),
    );

    if (resultado == true) {
      _carregarCategorias();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarCategorias,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarParaFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregarCategorias,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_categorias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma categoria cadastrada',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + para adicionar',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarCategorias,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final categoria = _categorias[index];
          return _buildCategoriaCard(categoria);
        },
      ),
    );
  }

  Widget _buildCategoriaCard(Categoria categoria) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            categoria.nomeCategoria[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          categoria.nomeCategoria,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: categoria.descricao != null && categoria.descricao!.isNotEmpty
            ? Text(
                categoria.descricao!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : const Text(
                'Sem descrição',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navegarParaFormulario(categoria: categoria),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletarCategoria(categoria),
              tooltip: 'Excluir',
            ),
          ],
        ),
        onTap: () => _navegarParaFormulario(categoria: categoria),
      ),
    );
  }
}