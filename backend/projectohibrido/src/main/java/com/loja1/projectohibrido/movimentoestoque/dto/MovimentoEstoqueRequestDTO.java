package com.loja1.projectohibrido.movimentoestoque.dto;

import lombok.Data;

@Data
public class MovimentoEstoqueRequestDTO {
    private Integer idProduto;
    private Integer idUsuario;
    private String tipoMovimento;
    private Integer quantidade;
    private Integer quantidadeAnterior;
    private Integer quantidadeNova;
    private String motivo;
}