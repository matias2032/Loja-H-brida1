package com.loja1.projectohibrido.usuario.controller;


import com.loja1.projectohibrido.usuario.dto.request.UsuarioCreateRequest;
import com.loja1.projectohibrido.usuario.dto.request.UsuarioUpdateRequest;
import com.loja1.projectohibrido.usuario.dto.response.UsuarioResponse;
import com.loja1.projectohibrido.usuario.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
@Slf4j

public class UsuarioController {

    private final UsuarioService usuarioService;

   
    
    @GetMapping
    public ResponseEntity<List<UsuarioResponse>> listarUsuarios(
            @RequestParam(required = false) Integer perfil,
            @RequestParam(required = false) Integer ativo
    ) {
        log.info("GET /api/usuarios - Perfil: {}, Ativo: {}", perfil, ativo);
        
        List<UsuarioResponse> usuarios = usuarioService.listarUsuarios(perfil, ativo);
        
        return ResponseEntity.ok(usuarios);
    }

    /**
     * GET /api/usuarios/{id}
     * Busca detalhes completos de um usuário
     */
    @GetMapping("/{id}")
    public ResponseEntity<UsuarioResponse> buscarPorId(@PathVariable Integer id) {
        log.info("GET /api/usuarios/{}", id);
        
        UsuarioResponse usuario = usuarioService.buscarPorId(id);
        
        return ResponseEntity.ok(usuario);
    }

    /**
     * POST /api/usuarios
     * Cria novo usuário
     */
    @PostMapping
    public ResponseEntity<UsuarioResponse> criarUsuario(
            @Valid @RequestBody UsuarioCreateRequest request
    ) {
        log.info("POST /api/usuarios - Email: {}", request.getEmail());
        
        UsuarioResponse usuario = usuarioService.criarUsuario(request);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(usuario);
    }

    /**
     * PUT /api/usuarios/{id}
     * Atualiza dados completos de um usuário
     */
    @PutMapping("/{id}")
    public ResponseEntity<UsuarioResponse> atualizarUsuario(
            @PathVariable Integer id,
            @Valid @RequestBody UsuarioUpdateRequest request
    ) {
        log.info("PUT /api/usuarios/{}", id);
        
        UsuarioResponse usuario = usuarioService.atualizarUsuario(id, request);
        
        return ResponseEntity.ok(usuario);
    }

    /**
     * PATCH /api/usuarios/{id}/toggle-status
     * Alterna entre ativo/inativo (Soft Delete)
     */
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<UsuarioResponse> toggleStatus(@PathVariable Integer id) {
        log.info("PATCH /api/usuarios/{}/toggle-status", id);
        
        UsuarioResponse usuario = usuarioService.toggleStatus(id);
        
        return ResponseEntity.ok(usuario);
    }

    /**
     * PATCH /api/usuarios/{id}/reset-password
     * Reseta senha para o padrão (12345678)
     */
    @PatchMapping("/{id}/reset-password")
    public ResponseEntity<UsuarioResponse> resetarSenha(@PathVariable Integer id) {
        log.info("PATCH /api/usuarios/{}/reset-password", id);
        
        UsuarioResponse usuario = usuarioService.resetarSenha(id);
        
        return ResponseEntity.ok(usuario);
    }
}
