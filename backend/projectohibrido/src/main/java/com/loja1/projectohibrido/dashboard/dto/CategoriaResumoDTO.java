package com.loja1.projectohibrido.dashboard.dto;

import java.math.BigDecimal;
import com.fasterxml.jackson.annotation.JsonProperty;
// import java.util.List;

public record CategoriaResumoDTO(
    @JsonProperty("nome_categoria") String nomeCategoria,
    @JsonProperty("total_vendas")   BigDecimal totalVendas
) {}
