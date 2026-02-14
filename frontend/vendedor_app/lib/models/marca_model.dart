// lib/models/marca_model.dart

class Marca {
  final int? idMarca;
  final String nomeMarca;

  Marca({
    this.idMarca,
    required this.nomeMarca,
  });

  factory Marca.fromJson(Map<String, dynamic> json) {
    return Marca(
      idMarca: json['idMarca'],
      nomeMarca: json['nomeMarca'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMarca != null) 'idMarca': idMarca,
      'nomeMarca': nomeMarca,
    };
  }

  @override
  String toString() {
    return 'Marca{idMarca: $idMarca, nomeMarca: $nomeMarca}';
  }
}