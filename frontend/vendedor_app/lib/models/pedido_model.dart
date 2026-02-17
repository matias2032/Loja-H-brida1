//pedido_model.dart
class ItemPedido {
  final int? idItemPedido;
  final int idProduto;
  final String nomeProduto;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;

  ItemPedido({
    this.idItemPedido,
    required this.idProduto,
    required this.nomeProduto,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    return ItemPedido(
      idItemPedido:  json['idItemPedido'],
      idProduto:     json['idProduto'],
      nomeProduto:   json['nomeProduto'] ?? '',
      quantidade:    json['quantidade'] ?? 1,
      precoUnitario: (json['precoUnitario'] as num).toDouble(),
      subtotal:      (json['subtotal']      as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idItemPedido != null) 'idItemPedido': idItemPedido,
      'idProduto':     idProduto,
      'quantidade':    quantidade,
      'precoUnitario': precoUnitario,
      'subtotal':      subtotal,
    };
  }

  ItemPedido copyWith({
    int? idItemPedido,
    int? idProduto,
    String? nomeProduto,
    int? quantidade,
    double? precoUnitario,
    double? subtotal,
  }) {
    return ItemPedido(
      idItemPedido:  idItemPedido  ?? this.idItemPedido,
      idProduto:     idProduto     ?? this.idProduto,
      nomeProduto:   nomeProduto   ?? this.nomeProduto,
      quantidade:    quantidade    ?? this.quantidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      subtotal:      subtotal      ?? this.subtotal,
    );
  }

  @override
  String toString() {
    return 'ItemPedido{idItemPedido: $idItemPedido, nomeProduto: $nomeProduto, quantidade: $quantidade, subtotal: $subtotal}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pedido
// ═══════════════════════════════════════════════════════════════════════════

class Pedido {
  final int? idPedido;
  final String? reference;
  final int idUsuario;
  final String? telefone;
  final String? email;
  final int idTipoPagamento;
  final int? idTipoEntrega;
  final int? idTipoOrigemPedido;
  final DateTime? dataPedido;
  final String statusPedido;
  final double total;
  final String? enderecoJson;
  final String? bairro;
  final String? pontoReferencia;
  final double troco;
  final List<ItemPedido> itens;

  Pedido({
    this.idPedido,
    this.reference,
    required this.idUsuario,
    this.telefone,
    this.email,
    required this.idTipoPagamento,
    this.idTipoEntrega,
    this.idTipoOrigemPedido,
    this.dataPedido,
    this.statusPedido = 'por finalizar',
    this.total = 0.0,
    this.enderecoJson,
    this.bairro,
    this.pontoReferencia,
    this.troco = 0.0,
    this.itens = const [],
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido:           json['idPedido'],
      reference:          json['reference'],
      idUsuario:          json['idUsuario'],
      telefone:           json['telefone'],
      email:              json['email'],
      idTipoPagamento:    json['idTipoPagamento'] ?? 1,
      idTipoEntrega:      json['idTipoEntrega'],
      idTipoOrigemPedido: json['idTipoOrigemPedido'],
      dataPedido: json['dataPedido'] != null
          ? DateTime.parse(json['dataPedido'])
          : null,
      statusPedido:    json['statusPedido'] ?? 'por finalizar',
      total:           (json['total'] as num? ?? 0).toDouble(),
      enderecoJson:    json['enderecoJson'],
      bairro:          json['bairro'],
      pontoReferencia: json['pontoReferencia'],
      troco:           (json['troco'] as num? ?? 0).toDouble(),
      itens: json['itens'] != null
          ? List<ItemPedido>.from(
              (json['itens'] as List).map((e) => ItemPedido.fromJson(e)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idPedido != null) 'idPedido': idPedido,
      'idUsuario':          idUsuario,
      'telefone':           telefone,
      'email':              email,
      'idTipoPagamento':    idTipoPagamento,
      'idTipoEntrega':      idTipoEntrega,
      'idTipoOrigemPedido': idTipoOrigemPedido,
      'enderecoJson':       enderecoJson,
      'bairro':             bairro,
      'pontoReferencia':    pontoReferencia,
      'itens':              itens.map((e) => e.toJson()).toList(),
    };
  }

  // Para criação — body limpo enviado ao POST /api/pedidos
  Map<String, dynamic> toJsonCreate() {
    return {
      'idUsuario':          idUsuario,
      'telefone':           telefone,
      'email':              email,
      'idTipoPagamento':    idTipoPagamento,
      'idTipoEntrega':      idTipoEntrega,
      'idTipoOrigemPedido': idTipoOrigemPedido,
      'enderecoJson':       enderecoJson,
      'bairro':             bairro,
      'pontoReferencia':    pontoReferencia,
      'itens':              itens.map((e) => e.toJson()).toList(),
    };
  }

  // ─── Helpers de negócio ──────────────────────────────────────────────────

  /// Pedido pode ter itens adicionados / editados / removidos
  bool get editavel => const [
    'por finalizar',
    'pendente',
    'em preparacao',
  ].contains(statusPedido);

  /// Pedido pode ser cancelado
  bool get cancelavel =>
      statusPedido != 'cancelado' && statusPedido != 'finalizado';

  /// Soma das quantidades de todos os itens
  int get totalItens =>
      itens.fold(0, (soma, item) => soma + item.quantidade);

  Pedido copyWith({
    int? idPedido,
    String? reference,
    int? idUsuario,
    String? telefone,
    String? email,
    int? idTipoPagamento,
    int? idTipoEntrega,
    int? idTipoOrigemPedido,
    DateTime? dataPedido,
    String? statusPedido,
    double? total,
    String? enderecoJson,
    String? bairro,
    String? pontoReferencia,
    double? troco,
    List<ItemPedido>? itens,
  }) {
    return Pedido(
      idPedido:           idPedido           ?? this.idPedido,
      reference:          reference          ?? this.reference,
      idUsuario:          idUsuario          ?? this.idUsuario,
      telefone:           telefone           ?? this.telefone,
      email:              email              ?? this.email,
      idTipoPagamento:    idTipoPagamento    ?? this.idTipoPagamento,
      idTipoEntrega:      idTipoEntrega      ?? this.idTipoEntrega,
      idTipoOrigemPedido: idTipoOrigemPedido ?? this.idTipoOrigemPedido,
      dataPedido:         dataPedido         ?? this.dataPedido,
      statusPedido:       statusPedido       ?? this.statusPedido,
      total:              total              ?? this.total,
      enderecoJson:       enderecoJson       ?? this.enderecoJson,
      bairro:             bairro             ?? this.bairro,
      pontoReferencia:    pontoReferencia    ?? this.pontoReferencia,
      troco:              troco              ?? this.troco,
      itens:              itens              ?? this.itens,
    );
  }

  @override
  String toString() {
    return 'Pedido{idPedido: $idPedido, reference: $reference, statusPedido: $statusPedido, total: $total}';
  }
}