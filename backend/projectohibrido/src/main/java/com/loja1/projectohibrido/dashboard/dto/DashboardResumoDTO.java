package com.loja1.projectohibrido.dashboard.dto;

import java.util.List;
// import com.fasterxml.jackson.annotation.JsonProperty;


public record DashboardResumoDTO(
    List<EvolucaoVendasDTO> evolucaoVendas,
    List<CategoriaResumoDTO> vendasPorCategoria,
    List<MarcaResumoDTO> vendasPorMarca,
    List<ProdutoTopDTO> top5Produtos,
    List<ProdutoNaoVendidoDTO> produtosNaoVendidos,
    List<DesempenhoUsuarioDTO> desempenhoUsuarios
) {}
