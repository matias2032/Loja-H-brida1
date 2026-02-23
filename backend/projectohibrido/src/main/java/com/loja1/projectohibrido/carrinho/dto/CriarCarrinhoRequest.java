package com.loja1.projectohibrido.carrinho.dto;

/**
 * Payload de criação de carrinho.
 * idUsuario e sessionId são ambos opcionais no body —
 * o controller resolve o idUsuario a partir do token JWT (se autenticado)
 * e o sessionId a partir do cookie (se guest).
 * Este DTO existe para casos em que a criação vem de um contexto administrativo
 * ou de testes onde nenhum dos dois contextos está disponível via request.
 */
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