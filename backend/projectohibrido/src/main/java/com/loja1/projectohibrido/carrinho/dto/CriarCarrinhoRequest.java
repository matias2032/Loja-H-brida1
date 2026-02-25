package com.loja1.projectohibrido.carrinho.dto;


public class CriarCarrinhoRequest {

    private Integer idUsuario;   // null para utilizador não autenticado
    private String  sessionId;   // null para utilizador autenticado

    // ── Constructors ──────────────────────────────────────────────────────────

    public CriarCarrinhoRequest() {}

    public CriarCarrinhoRequest(Integer idUsuario, String sessionId) {
        this.idUsuario = idUsuario;
        this.sessionId = sessionId;
    }

    // ── Getters & Setters ─────────────────────────────────────────────────────

    public Integer getIdUsuario()                   { return idUsuario; }
    public void setIdUsuario(Integer idUsuario)     { this.idUsuario = idUsuario; }

    public String getSessionId()                    { return sessionId; }
    public void setSessionId(String sessionId)      { this.sessionId = sessionId; }
}