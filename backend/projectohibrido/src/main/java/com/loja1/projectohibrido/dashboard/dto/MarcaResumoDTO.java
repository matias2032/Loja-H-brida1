package com.loja1.projectohibrido.dashboard.dto;

import java.math.BigDecimal;
// import java.util.List;
import com.fasterxml.jackson.annotation.JsonProperty;


public record MarcaResumoDTO(
    @JsonProperty("nome_marca")  String nomeMarca,
    @JsonProperty("total_vendas") BigDecimal totalVendas
) {}