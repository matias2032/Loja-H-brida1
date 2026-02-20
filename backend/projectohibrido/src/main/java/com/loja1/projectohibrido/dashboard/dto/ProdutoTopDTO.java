package com.loja1.projectohibrido.dashboard.dto;

import java.math.BigDecimal;
import com.fasterxml.jackson.annotation.JsonProperty;


public record ProdutoTopDTO(
    @JsonProperty("nome_produto")       String nomeProduto,
    @JsonProperty("quantidade_vendida") Long quantidadeVendida,
    @JsonProperty("receita_total")      BigDecimal receitaTotal,
    @JsonProperty("num_pedidos")        Long numPedidos
) {}