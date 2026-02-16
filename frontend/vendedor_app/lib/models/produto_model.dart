
//produto_model.dart

class Produto {
  final int? idProduto;
  final String nomeProduto;
  final String? descricao;
  final double preco;
  final int quantidadeEstoque;
  final double? precoPromocional;
  final int ativo;
  final DateTime? dataCadastro;
  final List<int> categorias;
  final List<int> marcas;
  final String? imagemPrincipalUrl;

  Produto({
    this.idProduto,
    required this.nomeProduto,
    this.descricao,
    required this.preco,
    required this.quantidadeEstoque,
    this.precoPromocional,
    this.ativo = 1,
    this.dataCadastro,
    this.categorias = const [],
    this.marcas = const [],
    this.imagemPrincipalUrl,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      idProduto: json['idProduto'],
      nomeProduto: json['nomeProduto'] ?? '',
      descricao: json['descricao'],
      preco: (json['preco'] as num).toDouble(),
      quantidadeEstoque: json['quantidadeEstoque'] ?? 0,
      precoPromocional: json['precoPromocional'] != null 
          ? (json['precoPromocional'] as num).toDouble() 
          : null,
      ativo: json['ativo'] ?? 1,
      dataCadastro: json['dataCadastro'] != null 
          ? DateTime.parse(json['dataCadastro']) 
          : null,
      categorias: json['categorias'] != null 
          ? List<int>.from(json['categorias']) 
          : [],
      marcas: json['marcas'] != null 
          ? List<int>.from(json['marcas']) 
          : [],
      imagemPrincipalUrl: json['imagemPrincipalUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idProduto != null) 'idProduto': idProduto,
      'nomeProduto': nomeProduto,
      'descricao': descricao,
      'preco': preco,
      'quantidadeEstoque': quantidadeEstoque,
      'precoPromocional': precoPromocional,
      'ativo': ativo,
      'categorias': categorias,
      'marcas': marcas,
    };
  }

// Método para criar (sem ID)
Map<String, dynamic> toJsonCreate() {
  return {
    'nomeProduto': nomeProduto,
    'descricao': descricao,
    'preco': preco,
    'quantidadeEstoque': quantidadeEstoque,
    'precoPromocional': precoPromocional,
    'categorias': categorias,
    'marcas': marcas,
  };
}

// ✅ NOVO: Método para atualizar (preserva categorias/marcas se vazias)
Map<String, dynamic> toJsonUpdate() {
  return {
    'nomeProduto': nomeProduto,
    'descricao': descricao,
    'preco': preco,
    'quantidadeEstoque': quantidadeEstoque,
    'precoPromocional': precoPromocional,
    // Só incluir se não estiver vazio
    if (categorias.isNotEmpty) 'categorias': categorias,
    if (marcas.isNotEmpty) 'marcas': marcas,
  };
}

  Produto copyWith({
    int? idProduto,
    String? nomeProduto,
    String? descricao,
    double? preco,
    int? quantidadeEstoque,
    double? precoPromocional,
    int? ativo,
    DateTime? dataCadastro,
    List<int>? categorias,
    List<int>? marcas,
    String? imagemPrincipalUrl,
  }) {
    return Produto(
      idProduto: idProduto ?? this.idProduto,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      quantidadeEstoque: quantidadeEstoque ?? this.quantidadeEstoque,
      precoPromocional: precoPromocional ?? this.precoPromocional,
      ativo: ativo ?? this.ativo,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      categorias: categorias ?? this.categorias,
      marcas: marcas ?? this.marcas,
      imagemPrincipalUrl: imagemPrincipalUrl ?? this.imagemPrincipalUrl,
    );
  }

  @override
  String toString() {
    return 'Produto{idProduto: $idProduto, nomeProduto: $nomeProduto, preco: $preco}';
  }
}