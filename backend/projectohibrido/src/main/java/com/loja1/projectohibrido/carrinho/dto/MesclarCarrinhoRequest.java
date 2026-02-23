package com.loja1.projectohibrido.carrinho.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Enviado pelo frontend após o login, para que o carrinho guest
 * (identificado pelo sessionId do cookie) seja mesclado ao carrinho
 * do utilizador autenticado.
 */
public class MesclarCarrinhoRequest {

    @NotBlank(message = "O sessionId do carrinho guest é obrigatório")
    private String sessionId;

    // ── Constructors ──────────────────────────────────────────────────────────

    public MesclarCarrinhoRequest() {}

    public MesclarCarrinhoRequest(String sessionId) {
        this.sessionId = sessionId;
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public String getSessionId()                    { return sessionId; }
    public void setSessionId(String sessionId)      { this.sessionId = sessionId; }
}