package com.loja1.projectohibrido.movimentoestoque.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class MovimentoEstoqueResponseDTO {
    private Integer idMovimento;
    private Integer idProduto;
    private Integer idUsuario;
    private String tipoMovimento;
    private Integer quantidade;
    private Integer quantidadeAnterior;
    private Integer quantidadeNova;
    private String motivo;
    private LocalDateTime dataMovimento;
    private String nomeProduto;
private String nomeUsuario;

}