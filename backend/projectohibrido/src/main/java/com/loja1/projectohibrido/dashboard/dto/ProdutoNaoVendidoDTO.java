
package com.loja1.projectohibrido.dashboard.dto;

import java.math.BigDecimal;
import com.fasterxml.jackson.annotation.JsonProperty;

// import java.util.List;


public record ProdutoNaoVendidoDTO(
    @JsonProperty("nome_produto")        String nomeProduto,
    @JsonProperty("quantidade_estoque")  Integer quantidadeEstoque,
    @JsonProperty("preco")               BigDecimal preco
) {}