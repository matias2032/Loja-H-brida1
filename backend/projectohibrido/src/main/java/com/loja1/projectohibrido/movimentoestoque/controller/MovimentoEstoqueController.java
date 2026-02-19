package com.loja1.projectohibrido.movimentoestoque.controller;

import com.loja1.projectohibrido.movimentoestoque.dto.MovimentoEstoqueRequestDTO;
import com.loja1.projectohibrido.movimentoestoque.dto.MovimentoEstoqueResponseDTO;
import com.loja1.projectohibrido.movimentoestoque.service.MovimentoEstoqueService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/movimentos_estoque")
@RequiredArgsConstructor
@Slf4j
public class MovimentoEstoqueController {

    private final MovimentoEstoqueService service;

    @PostMapping
    public ResponseEntity<MovimentoEstoqueResponseDTO> registrar(
            @RequestBody MovimentoEstoqueRequestDTO dto) {
        log.info("POST /api/movimentos_estoque | produto={}", dto.getIdProduto());
        return ResponseEntity.status(HttpStatus.CREATED).body(service.registrar(dto));
    }

    @GetMapping("/produto/{idProduto}")
    public ResponseEntity<List<MovimentoEstoqueResponseDTO>> listarPorProduto(
            @PathVariable Integer idProduto) {
        log.info("GET /api/movimentos_estoque/produto/{}", idProduto);
        return ResponseEntity.ok(service.listarPorProduto(idProduto));
    }

    @GetMapping
    public ResponseEntity<List<MovimentoEstoqueResponseDTO>> listarTodos() {
        log.info("GET /api/movimentos_estoque | listando todos");
        return ResponseEntity.ok(service.listarTodos());
    }

    @GetMapping("/periodo")
    public ResponseEntity<List<MovimentoEstoqueResponseDTO>> listarPorPeriodo(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime fim) {
        log.info("GET /api/movimentos_estoque/periodo | {} → {}", inicio, fim);
        return ResponseEntity.ok(service.listarPorPeriodo(inicio, fim));
    }
}