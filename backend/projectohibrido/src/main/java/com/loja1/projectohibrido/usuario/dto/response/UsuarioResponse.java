package com.loja1.projectohibrido.usuario.dto.response;


import com.loja1.projectohibrido.usuario.entity.Usuario;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UsuarioResponse {

    private Integer idUsuario;
    private String nome;
    private String apelido;
    private String email;
    private String telefone;
    private Integer ativo;
    private String statusDescricao; // "Ativo" ou "Inativo"
    
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime dataCadastro;
    
    private Integer idProvincia;
    private Integer idCidade;
    private Integer idPerfil;
    private String perfilDescricao; // Será preenchido posteriormente se necessário
    private Integer primeiraSenha;

    /**
     * Método estático para converter Entity em DTO
     * IMPORTANTE: senha_hash NUNCA é exposta
     */
    public static UsuarioResponse fromEntity(Usuario usuario) {
        if (usuario == null) {
            return null;
        }

        return UsuarioResponse.builder()
                .idUsuario(usuario.getIdUsuario())
                .nome(usuario.getNome())
                .apelido(usuario.getApelido())
                .email(usuario.getEmail())
                .telefone(usuario.getTelefone())
                .ativo(usuario.getAtivo())
                .statusDescricao(usuario.getAtivo() == 1 ? "Ativo" : "Inativo")
                .dataCadastro(usuario.getDataCadastro())
                .idProvincia(usuario.getIdProvincia())
                .idCidade(usuario.getIdCidade())
                .idPerfil(usuario.getIdPerfil())
                .primeiraSenha(usuario.getPrimeiraSenha())
                .build();
    }
}

