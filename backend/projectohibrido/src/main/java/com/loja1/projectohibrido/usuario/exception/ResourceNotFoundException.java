package com.loja1.projectohibrido.usuario.exception;


/**
 * Exceção lançada quando um recurso não é encontrado
 */
public class ResourceNotFoundException extends RuntimeException {
    
    public ResourceNotFoundException(String message) {
        super(message);
    }
    
    public ResourceNotFoundException(String message, Throwable cause) {
        super(message, cause);
    }
}