// lib/models/usuario_model.dart

class UsuarioModel {
  final int idUsuario;
  final String nome;
  final String apelido;
  final String email;
  final String? telefone;
  final int ativo;
  final String statusDescricao;
  final DateTime dataCadastro;
  final int? idProvincia;
  final int? idCidade;
  final int idPerfil;
  final int primeiraSenha;

  UsuarioModel({
    required this.idUsuario,
    required this.nome,
    required this.apelido,
    required this.email,
    this.telefone,
    required this.ativo,
    required this.statusDescricao,
    required this.dataCadastro,
    this.idProvincia,
    this.idCidade,
    required this.idPerfil,
    required this.primeiraSenha,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      idUsuario: json['idUsuario'],
      nome: json['nome'],
      apelido: json['apelido'],
      email: json['email'],
      telefone: json['telefone'],
      ativo: json['ativo'],
      statusDescricao: json['statusDescricao'],
      dataCadastro: DateTime.parse(json['dataCadastro']),
      idProvincia: json['idProvincia'],
      idCidade: json['idCidade'],
      idPerfil: json['idPerfil'],
      primeiraSenha: json['primeiraSenha'],
    );
  }
}