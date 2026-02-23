package com.loja1.projectohibrido.carrinho.exception;

import jakarta.persistence.EntityNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Handler centralizado para as exceções do módulo Carrinho.
 * Garante respostas padronizadas com timestamp, status e mensagem descritiva.
 *
 * Caso o projecto já possua um GlobalExceptionHandler partilhado (em shared/),
 * mova apenas os @ExceptionHandler específicos do carrinho para lá e elimine
 * os handlers genéricos (EntityNotFoundException, MethodArgumentNotValidException)
 * para evitar duplicidade.
 */
@RestControllerAdvice(basePackages = "com.loja1.projectohibrido.carrinho")
public class CarrinhoGlobalExceptionHandler {

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Map<String, Object> buildBody(HttpStatus status, String mensagem) {
        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", LocalDateTime.now().toString());
        body.put("status",    status.value());
        body.put("erro",      status.getReasonPhrase());
        body.put("mensagem",  mensagem);
        return body;
    }

    // ── Handlers específicos do carrinho ──────────────────────────────────────

    @ExceptionHandler(EstoqueInsuficienteException.class)
    public ResponseEntity<Map<String, Object>> handleEstoqueInsuficiente(EstoqueInsuficienteException ex) {
        Map<String, Object> body = buildBody(HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage());

        // Inclui detalhes extras apenas quando disponíveis
        if (ex.getIdProduto() != null) {
            body.put("idProduto",            ex.getIdProduto());
            body.put("nomeProduto",          ex.getNomeProduto());
            body.put("estoqueDisponivel",    ex.getEstoqueDisponivel());
            body.put("quantidadeSolicitada", ex.getQuantidadeSolicitada());
        }

        return ResponseEntity.unprocessableEntity().body(body);
    }

    @ExceptionHandler(CarrinhoNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleCarrinhoNotFound(CarrinhoNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                             .body(buildBody(HttpStatus.NOT_FOUND, ex.getMessage()));
    }

    @ExceptionHandler(ItemCarrinhoNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleItemNotFound(ItemCarrinhoNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                             .body(buildBody(HttpStatus.NOT_FOUND, ex.getMessage()));
    }

    @ExceptionHandler(CarrinhoVazioException.class)
    public ResponseEntity<Map<String, Object>> handleCarrinhoVazio(CarrinhoVazioException ex) {
        return ResponseEntity.badRequest()
                             .body(buildBody(HttpStatus.BAD_REQUEST, ex.getMessage()));
    }

    @ExceptionHandler(CarrinhoJaConvertidoException.class)
    public ResponseEntity<Map<String, Object>> handleCarrinhoJaConvertido(CarrinhoJaConvertidoException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                             .body(buildBody(HttpStatus.CONFLICT, ex.getMessage()));
    }

    // ── Handlers genéricos (remover se já existirem no GlobalExceptionHandler) ─

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleEntityNotFound(EntityNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                             .body(buildBody(HttpStatus.NOT_FOUND, ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errosCampos = new HashMap<>();
        for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
            errosCampos.put(fe.getField(), fe.getDefaultMessage());
        }
        Map<String, Object> body = buildBody(HttpStatus.BAD_REQUEST, "Erro de validação nos campos enviados");
        body.put("campos", errosCampos);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalState(IllegalStateException ex) {
        return ResponseEntity.badRequest()
                             .body(buildBody(HttpStatus.BAD_REQUEST, ex.getMessage()));
    }
}