package com.loja1.projectohibrido.dashboard.dto;

import java.math.BigDecimal;
import com.fasterxml.jackson.annotation.JsonProperty;


public record EvolucaoVendasDTO(
    @JsonProperty("data")         String data,
    @JsonProperty("total_vendas") BigDecimal totalVendas
) {}
