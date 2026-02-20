package com.loja1.projectohibrido.usuario.controller;

import java.util.Map;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.loja1.projectohibrido.usuario.dto.response.UsuarioResponse;
import com.loja1.projectohibrido.usuario.entity.Usuario;
import com.loja1.projectohibrido.usuario.repository.UsuarioRepository;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    // ── Logger ────────────────────────────────────────────────────────────────
    // Logs visíveis na consola do Spring Boot (INFO e acima por padrão)
    // Para ver logs DEBUG, adicionar em application.properties:
    //   logging.level.com.loja1.projectohibrido.usuario.controller=DEBUG
    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final UsuarioRepository usuarioRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    // ── POST /api/auth/login ─────────────────────────────────────────────────
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {

        String credencial = body.get("credencial");
        String senha      = body.get("senha");

        // ── Log 1: Início do processo de login ────────────────────────────
        log.info("═══════════════════════════════════════════");
        log.info("🔐 TENTATIVA DE LOGIN");
        log.info("   Credencial recebida : '{}'", credencial);
        log.info("   Senha recebida      : {} caracteres", senha != null ? senha.length() : 0);

        // ── Validação de campos vazios ─────────────────────────────────────
        if (credencial == null || credencial.isBlank() || senha == null || senha.isBlank()) {
            log.warn("⚠️  Campos em branco — credencial='{}', senha presente={}", credencial, senha != null);
            return ResponseEntity.status(400)
                    .body(Map.of("message", "Credencial e senha são obrigatórios."));
        }

        // ── Log 2: Busca na base de dados ─────────────────────────────────
        log.debug("🔍 Pesquisando usuário por email/telefone/apelido: '{}'", credencial);
        Optional<Usuario> opt = usuarioRepository.findByEmailOrTelefoneOrApelido(credencial);

        if (opt.isEmpty()) {
            log.warn("❌ FALHA — Nenhum usuário encontrado para credencial: '{}'", credencial);
            return ResponseEntity.status(401)
                    .body(Map.of("message", "Credencial ou senha incorretos."));
        }

        Usuario u = opt.get();

        // ── Log 3: Usuário encontrado ──────────────────────────────────────
        log.info("✅ Usuário encontrado:");
        log.info("   ID        : {}", u.getIdUsuario());
        log.info("   Nome      : {} {}", u.getNome(), u.getApelido());
        log.info("   Email     : {}", u.getEmail());
        log.info("   Perfil    : {}", u.getIdPerfil());
        log.info("   Ativo     : {}", u.getAtivo());
        log.info("   1ª Senha  : {}", u.getPrimeiraSenha());

        // ── Log 4: Diagnóstico do hash ─────────────────────────────────────
        String hashArmazenado = u.getSenhaHash();
        log.debug("🔑 Hash armazenado na BD : '{}'",
                hashArmazenado != null ? hashArmazenado.substring(0, Math.min(20, hashArmazenado.length())) + "..." : "NULL");

        if (hashArmazenado != null) {
            log.debug("   Prefixo do hash       : '{}'", hashArmazenado.substring(0, Math.min(4, hashArmazenado.length())));
            log.debug("   Comprimento do hash   : {} caracteres", hashArmazenado.length());
        }

        // ── Verificação de conta inativa ───────────────────────────────────
        if (u.getAtivo() == 0) {
            log.warn("🚫 Usuário ID={} está INATIVO — acesso negado", u.getIdUsuario());
            return ResponseEntity.status(401)
                    .body(Map.of("message", "Conta inativa. Contacte o administrador.", "inativo", true));
        }

        // ── 🔥 CORREÇÃO PRINCIPAL: normalizar prefixo $2b$ → $2a$ ─────────
        // O BCrypt do Flutter/Node.js gera hashes com prefixo $2b$
        // O Spring Security usa $2a$ — são idênticos funcionalmente
        // mas o BCryptPasswordEncoder do Java rejeita $2b$ por padrão
        String hashParaVerificar = normalizarHashBcrypt(hashArmazenado);

        if (!hashArmazenado.equals(hashParaVerificar)) {
            log.info("🔄 Hash normalizado: prefixo '$2b$' convertido para '$2a$'");
        }

        // ── Log 5: Antes da verificação de senha ──────────────────────────
        log.debug("🔓 Iniciando verificação BCrypt...");
        log.debug("   Senha digitada : {} chars", senha.length());
        log.debug("   Hash para check: {}...", hashParaVerificar.substring(0, Math.min(20, hashParaVerificar.length())));

        boolean senhaCorreta = passwordEncoder.matches(senha, hashParaVerificar);

        // ── Log 6: Resultado da verificação ───────────────────────────────
        log.info("   BCrypt.matches() → {}", senhaCorreta ? "✅ CORRETO" : "❌ INCORRETO");

        if (!senhaCorreta) {
            log.warn("❌ FALHA — Senha incorreta para usuário ID={} ({})", u.getIdUsuario(), credencial);
            return ResponseEntity.status(401)
                    .body(Map.of("message", "Credencial ou senha incorretos."));
        }

        // ── Log 7: Login aprovado ─────────────────────────────────────────
        log.info("✅ LOGIN APROVADO — Usuário: {} {} (ID={})",
                u.getNome(), u.getApelido(), u.getIdUsuario());
        log.info("   Redirecionamento: {}",
                u.getPrimeiraSenha() == 1 ? "→ TROCA OBRIGATÓRIA DE SENHA" : "→ DASHBOARD");
        log.info("═══════════════════════════════════════════");

        return ResponseEntity.ok(Map.of(
                "usuario",       UsuarioResponse.fromEntity(u),
                "primeiraSenha", u.getPrimeiraSenha() == 1
        ));
    }

    // ── PATCH /api/auth/{id}/trocar-senha ────────────────────────────────────
    @PatchMapping("/{id}/trocar-senha")
    public ResponseEntity<?> trocarSenha(
            @PathVariable Integer id,
            @RequestBody Map<String, String> body) {

        String novaSenha = body.get("novaSenha");

        log.info("🔄 TROCA DE SENHA — Usuário ID={}", id);
        log.debug("   Nova senha : {} caracteres", novaSenha != null ? novaSenha.length() : 0);

        if (novaSenha == null || novaSenha.isBlank()) {
            log.warn("⚠️  Nova senha em branco para ID={}", id);
            return ResponseEntity.status(400)
                    .body(Map.of("message", "A nova senha não pode estar vazia."));
        }

        return usuarioRepository.findById(id).map(u -> {
            // Novo hash gerado pelo Spring (sempre $2a$)
            String novoHash = passwordEncoder.encode(novaSenha);

            log.debug("   Novo hash gerado : {}...", novoHash.substring(0, Math.min(20, novoHash.length())));

            u.setSenhaHash(novoHash);
            u.setPrimeiraSenha(0);
            usuarioRepository.save(u);

            log.info("✅ Senha trocada com sucesso — Usuário ID={} ({} {})",
                    u.getIdUsuario(), u.getNome(), u.getApelido());

            return ResponseEntity.ok().build();
        }).orElseGet(() -> {
            log.warn("❌ Usuário ID={} não encontrado para troca de senha", id);
            return ResponseEntity.notFound().build();
        });
    }

    // ── PATCH /api/auth/{id}/alterar-senha ───────────────────────────────────
    // Chamado pela tela alterar_senha.dart (usuário já logado)
    @PatchMapping("/{id}/alterar-senha")
    public ResponseEntity<?> alterarSenha(
            @PathVariable Integer id,
            @RequestBody Map<String, String> body) {

        String senhaAtual = body.get("senhaAtual");
        String novaSenha  = body.get("novaSenha");

        log.info("🔐 ALTERAR SENHA — Usuário ID={}", id);

        return usuarioRepository.findById(id).map(u -> {

            // 🔥 Normalizar hash antes de verificar (mesmo fix do login)
            String hashNormalizado = normalizarHashBcrypt(u.getSenhaHash());
            boolean senhaAtualCorreta = passwordEncoder.matches(senhaAtual, hashNormalizado);

            log.debug("   Verificação senha atual → {}", senhaAtualCorreta ? "✅" : "❌");

            if (!senhaAtualCorreta) {
                log.warn("❌ Senha atual incorreta para ID={}", id);
                return ResponseEntity.status(400)
                        .body(Map.of("message", "Senha atual incorreta."));
            }

            u.setSenhaHash(passwordEncoder.encode(novaSenha));
            u.setPrimeiraSenha(0);
            usuarioRepository.save(u);

            log.info("✅ Senha alterada com sucesso — ID={}", id);
            return ResponseEntity.ok().build();

        }).orElseGet(() -> {
            log.warn("❌ Usuário ID={} não encontrado", id);
            return ResponseEntity.notFound().build();
        });
    }

    // ── Utilitário: normaliza $2b$ → $2a$ ────────────────────────────────────
    /**
     * O Flutter/Node.js gera hashes BCrypt com prefixo "$2b$".
     * O Spring Security BCryptPasswordEncoder usa "$2a$".
     * Ambos são idênticos algoritmicamente — só o prefixo difere.
     *
     * Esta conversão permite que hashes gerados fora do Java
     * sejam verificados correctamente pelo Spring.
     */
    private String normalizarHashBcrypt(String hash) {
        if (hash != null && hash.startsWith("$2b$")) {
            return "$2a$" + hash.substring(4);
        }
        return hash;
    }
}