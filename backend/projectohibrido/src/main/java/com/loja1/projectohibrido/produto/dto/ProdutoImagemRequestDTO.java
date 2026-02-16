package com.loja1.projectohibrido.produto.dto;

import lombok.Data;

@Data
public class ProdutoImagemRequestDTO {
    private String caminhoImagem;
    private String legenda;
    
    // ✅ MUDANÇA: Integer → Short
    private Short imagemPrincipal; // 0 ou 1
}