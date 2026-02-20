package com.loja1.projectohibrido.dashboard.service;
import com.loja1.projectohibrido.dashboard.dto.*;   // todos os DTOs de uma vez
import com.loja1.projectohibrido.pedido.repository.PedidoRepository;
import com.loja1.projectohibrido.pedido.repository.ItemPedidoRepository;
import com.loja1.projectohibrido.produto.repository.ProdutoRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;


@Service
@RequiredArgsConstructor
public class DashboardService {

    private final PedidoRepository pedidoRepository;
    private final ItemPedidoRepository itemPedidoRepository;
    private final ProdutoRepository produtoRepository;

    public List<EvolucaoVendasDTO> getEvolucaoVendas(LocalDateTime dataInicio) {
        return pedidoRepository.evolucaoVendasPorDia(dataInicio).stream()
            .map(row -> new EvolucaoVendasDTO(
                row[0].toString(),
                (BigDecimal) row[1]
            )).toList();
    }

    public List<CategoriaResumoDTO> getVendasPorCategoria(LocalDateTime dataInicio) {
        return itemPedidoRepository.vendasPorCategoria(dataInicio).stream()
            .map(row -> new CategoriaResumoDTO(
                (String) row[0],
                (BigDecimal) row[1]
            )).toList();
    }

    public List<MarcaResumoDTO> getVendasPorMarca(LocalDateTime dataInicio) {
        return itemPedidoRepository.vendasPorMarca(dataInicio).stream()
            .map(row -> new MarcaResumoDTO(
                (String) row[0],
                (BigDecimal) row[1]
            )).toList();
    }

    public List<ProdutoTopDTO> getTop5Produtos(LocalDateTime dataInicio) {
        return itemPedidoRepository.top5Produtos(dataInicio).stream()
            .map(row -> new ProdutoTopDTO(
                (String) row[0],
                ((Number) row[1]).longValue(),
                (BigDecimal) row[2],
                ((Number) row[3]).longValue()
            )).toList();
    }

    public List<ProdutoNaoVendidoDTO> getProdutosNaoVendidos(LocalDateTime dataInicio) {
        return produtoRepository.produtosSemVendas(dataInicio).stream()
            .map(row -> new ProdutoNaoVendidoDTO(
                (String) row[1],
                (Integer) row[2],
                (BigDecimal) row[3]
            )).toList();
    }

    public List<DesempenhoUsuarioDTO> getDesempenhoUsuarios(LocalDateTime dataInicio) {
    return pedidoRepository.desempenhoUsuarios(dataInicio).stream()
        .map(row -> new DesempenhoUsuarioDTO(
            row[0] + " " + row[1],   // nome + apelido
            "Funcionário",            // cargo fixo por ora
            ((Number) row[2]).longValue(),
            (BigDecimal) row[3],
            ((Number) row[4]).longValue()
        )).toList();
}
}

