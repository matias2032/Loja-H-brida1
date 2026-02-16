package com.loja1.projectohibrido.produto.controller;

import com.loja1.projectohibrido.produto.dto.ProdutoImagemRequestDTO;
import com.loja1.projectohibrido.produto.dto.ProdutoRequestDTO;
import com.loja1.projectohibrido.produto.dto.ProdutoResponseDTO;
import com.loja1.projectohibrido.produto.entity.ProdutoImagem;
import com.loja1.projectohibrido.produto.service.ProdutoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/produtos")
@RequiredArgsConstructor
public class ProdutoController {
    
    private final ProdutoService produtoService;
    
    @PostMapping
    public ResponseEntity<ProdutoResponseDTO> criar(@RequestBody ProdutoRequestDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(produtoService.criar(dto));
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<ProdutoResponseDTO> atualizar(
            @PathVariable Integer id, 
            @RequestBody ProdutoRequestDTO dto) {
        return ResponseEntity.ok(produtoService.atualizar(id, dto));
    }
    
    @PatchMapping("/{id}/toggle-ativo")
    public ResponseEntity<Void> toggleAtivo(@PathVariable Integer id) {
        produtoService.toggleAtivo(id);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping
    public ResponseEntity<List<ProdutoResponseDTO>> listar() {
        return ResponseEntity.ok(produtoService.listar());
    }
    
    @GetMapping("/ativos")
    public ResponseEntity<List<ProdutoResponseDTO>> listarAtivos() {
        return ResponseEntity.ok(produtoService.listarAtivos());
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ProdutoResponseDTO> buscarPorId(@PathVariable Integer id) {
        return ResponseEntity.ok(produtoService.buscarPorId(id));
    }
    
    // ===== CATEGORIAS =====
    
    @PostMapping("/{idProduto}/categorias/{idCategoria}")
    public ResponseEntity<Void> associarCategoria(
            @PathVariable Integer idProduto,
            @PathVariable Integer idCategoria) {
        produtoService.associarCategoria(idProduto, idCategoria);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
    
    @DeleteMapping("/{idProduto}/categorias/{idCategoria}")
    public ResponseEntity<Void> desassociarCategoria(
            @PathVariable Integer idProduto,
            @PathVariable Integer idCategoria) {
        produtoService.desassociarCategoria(idProduto, idCategoria);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{idProduto}/categorias")
    public ResponseEntity<List<Integer>> listarCategorias(@PathVariable Integer idProduto) {
        return ResponseEntity.ok(produtoService.listarCategoriasDoProduto(idProduto));
    }

    // ===== MARCAS =====

@PostMapping("/{idProduto}/marcas/{idMarca}")
public ResponseEntity<Void> associarMarca(
        @PathVariable Integer idProduto,
        @PathVariable Integer idMarca) {
    produtoService.associarMarca(idProduto, idMarca);
    return ResponseEntity.status(HttpStatus.CREATED).build();
}

@DeleteMapping("/{idProduto}/marcas/{idMarca}")
public ResponseEntity<Void> desassociarMarca(
        @PathVariable Integer idProduto,
        @PathVariable Integer idMarca) {
    produtoService.desassociarMarca(idProduto, idMarca);
    return ResponseEntity.noContent().build();
}

@GetMapping("/{idProduto}/marcas")
public ResponseEntity<List<Integer>> listarMarcas(@PathVariable Integer idProduto) {
    return ResponseEntity.ok(produtoService.listarMarcasDoProduto(idProduto));
}

@GetMapping("/marcas/{idMarca}/produtos")
public ResponseEntity<List<Integer>> listarProdutosPorMarca(@PathVariable Integer idMarca) {
    return ResponseEntity.ok(produtoService.listarProdutosDaMarca(idMarca));
}
    
    // ===== IMAGENS =====
    
    @PostMapping("/{idProduto}/imagens")
    public ResponseEntity<Void> adicionarImagem(
            @PathVariable Integer idProduto,
            @RequestBody ProdutoImagemRequestDTO dto) {
        produtoService.adicionarImagem(idProduto, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
    
    @PatchMapping("/{idProduto}/imagens/{idImagem}/principal")
    public ResponseEntity<Void> alterarImagemPrincipal(
            @PathVariable Integer idProduto,
            @PathVariable Integer idImagem) {
        produtoService.alterarImagemPrincipal(idProduto, idImagem);
        return ResponseEntity.noContent().build();
    }
    
    @DeleteMapping("/imagens/{idImagem}")
    public ResponseEntity<Void> removerImagem(@PathVariable Integer idImagem) {
        produtoService.removerImagem(idImagem);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/{idProduto}/imagens")
    public ResponseEntity<List<ProdutoImagem>> listarImagens(@PathVariable Integer idProduto) {
        return ResponseEntity.ok(produtoService.listarImagensDoProduto(idProduto));
    }
}