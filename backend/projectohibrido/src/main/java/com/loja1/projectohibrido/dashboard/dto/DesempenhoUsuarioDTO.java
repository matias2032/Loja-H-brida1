package com.loja1.projectohibrido.dashboard.dto;

import java.math.BigDecimal;
import com.fasterxml.jackson.annotation.JsonProperty;

// import java.util.List;


public record DesempenhoUsuarioDTO(
    @JsonProperty("nome_completo")  String nomeCompleto,
    @JsonProperty("cargo")          String cargo,
    @JsonProperty("total_pedidos")  Long totalPedidos,
    @JsonProperty("total_vendas")   BigDecimal totalVendas,
    @JsonProperty("dias_ativos")    Long diasAtivos
) {}