package com.loja1.projectohibrido.usuario.exception;

/**
 * Exceção lançada quando uma regra de negócio é violada
 */
public class BusinessException extends RuntimeException {
    
    public BusinessException(String message) {
        super(message);
    }
    
    public BusinessException(String message, Throwable cause) {
        super(message, cause);
    }
}