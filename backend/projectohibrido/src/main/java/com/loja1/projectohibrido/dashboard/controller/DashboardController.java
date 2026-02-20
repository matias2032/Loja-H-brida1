package com.loja1.projectohibrido.dashboard.controller;

import com.loja1.projectohibrido.dashboard.dto.*;
import com.loja1.projectohibrido.dashboard.service.DashboardService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@RestController
@RequestMapping("/api/v1/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    private LocalDateTime parseData(String dataInicio) {
        return LocalDateTime.parse(dataInicio, DateTimeFormatter.ISO_DATE_TIME);
    }

    @GetMapping("/evolucao-vendas")
    public ResponseEntity<List<EvolucaoVendasDTO>> evolucaoVendas(
            @RequestParam String dataInicio) {
        return ResponseEntity.ok(dashboardService.getEvolucaoVendas(parseData(dataInicio)));
    }

    @GetMapping("/vendas-por-categoria")
    public ResponseEntity<List<CategoriaResumoDTO>> vendasPorCategoria(
            @RequestParam String dataInicio) {
        return ResponseEntity.ok(dashboardService.getVendasPorCategoria(parseData(dataInicio)));
    }

    @GetMapping("/vendas-por-marca")
    public ResponseEntity<List<MarcaResumoDTO>> vendasPorMarca(
            @RequestParam String dataInicio) {
        return ResponseEntity.ok(dashboardService.getVendasPorMarca(parseData(dataInicio)));
    }

    @GetMapping("/top5-produtos")
    public ResponseEntity<List<ProdutoTopDTO>> top5Produtos(
            @RequestParam String dataInicio) {
        return ResponseEntity.ok(dashboardService.getTop5Produtos(parseData(dataInicio)));
    }

    @GetMapping("/produtos-nao-vendidos")
    public ResponseEntity<List<ProdutoNaoVendidoDTO>> produtosNaoVendidos(
            @RequestParam String dataInicio) {
        return ResponseEntity.ok(dashboardService.getProdutosNaoVendidos(parseData(dataInicio)));
    }

    @GetMapping("/desempenho-usuarios")
    public ResponseEntity<List<DesempenhoUsuarioDTO>> desempenhoUsuarios(
            @RequestParam String dataInicio) {
        return ResponseEntity.ok(dashboardService.getDesempenhoUsuarios(parseData(dataInicio)));
    }
}