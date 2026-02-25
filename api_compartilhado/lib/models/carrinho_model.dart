class ItemCarrinho {
  final int? idItemCarrinho;
  final int idProduto;
  final String nomeProduto;
  final String? imagemUrl;
  final double precoUnitario;
  final int quantidade;
  final double subtotal;

  ItemCarrinho({
    this.idItemCarrinho,
    required this.idProduto,
    required this.nomeProduto,
    this.imagemUrl,
    required this.precoUnitario,
    required this.quantidade,
    required this.subtotal,
  });

  factory ItemCarrinho.fromJson(Map<String, dynamic> json) => ItemCarrinho(
        idItemCarrinho: json['idItemCarrinho'],
        idProduto:      json['idProduto'],
        nomeProduto:    json['nomeProduto'] ?? '',
        imagemUrl:      json['imagemUrl'],
        precoUnitario:  (json['precoUnitario'] as num).toDouble(),
        quantidade:     json['quantidade'] ?? 1,
        subtotal:       (json['subtotal'] as num).toDouble(),
      );
}

class CarrinhoModel {
  final int idCarrinho;
  final int? idUsuario;
  final String? sessionId;
  final String status;
  final List<ItemCarrinho> itens;
  final double total;

  CarrinhoModel({
    required this.idCarrinho,
    this.idUsuario,
    this.sessionId,
    required this.status,
    required this.itens,
    required this.total,
  });

  factory CarrinhoModel.fromJson(Map<String, dynamic> json) => CarrinhoModel(
        idCarrinho: json['idCarrinho'],
        idUsuario:  json['idUsuario'],
        sessionId:  json['sessionId'],
        status:     json['status'] ?? 'activo',
        itens: (json['itens'] as List? ?? [])
            .map((e) => ItemCarrinho.fromJson(e))
            .toList(),
        total: (json['total'] as num? ?? 0).toDouble(),
      );

  int get totalItens => itens.fold(0, (s, i) => s + i.quantidade);
}