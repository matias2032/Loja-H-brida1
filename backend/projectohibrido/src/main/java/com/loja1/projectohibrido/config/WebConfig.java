package com.loja1.projectohibrido.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        // Permite CORS para todos os endpoints da API
        registry.addMapping("/**")
                // Permite qualquer origem (importante para o Flutter Web que muda de porta)
                .allowedOriginPatterns("*") 
                // Métodos permitidos
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
                // Cabeçalhos permitidos
                .allowedHeaders("*")
                // Permite envio de cookies/autenticação se necessário
                .allowCredentials(true);
    }
}