class MovimentoEstoque {
  final int? idMovimento;
  final int idProduto;
  final int idUsuario;
  final String tipoMovimento; // entrada | saida | ajuste
  final int quantidade;
  final int quantidadeAnterior;
  final int quantidadeNova;
  final String? motivo;
  final DateTime? dataMovimento;
  // ADICIONAR ao modelo:
final String? nomeProduto;
final String? nomeUsuario;

  MovimentoEstoque({
    this.idMovimento,
    required this.idProduto,
    required this.idUsuario,
    required this.tipoMovimento,
    required this.quantidade,
    required this.quantidadeAnterior,
    required this.quantidadeNova,
    this.motivo,
    this.dataMovimento,
    this.nomeProduto,
this.nomeUsuario,
  });

  factory MovimentoEstoque.fromJson(Map<String, dynamic> json) {
    return MovimentoEstoque(
      idMovimento: json['idMovimento'],
      idProduto: json['idProduto'],
      idUsuario: json['idUsuario'],
      tipoMovimento: json['tipoMovimento'],
      quantidade: json['quantidade'],
      quantidadeAnterior: json['quantidadeAnterior'],
      quantidadeNova: json['quantidadeNova'],
      motivo: json['motivo'],
      dataMovimento: json['dataMovimento'] != null
          ? DateTime.parse(json['dataMovimento'])
          : null,
      nomeProduto: json['nomeProduto'],
      nomeUsuario: json['nomeUsuario'],
    );
  }

  Map<String, dynamic> toJson() => {
        'idProduto': idProduto,
        'idUsuario': idUsuario,
        'tipoMovimento': tipoMovimento,
        'quantidade': quantidade,
        'quantidadeAnterior': quantidadeAnterior,
        'quantidadeNova': quantidadeNova,
        'motivo': motivo,
      };
}