package com.loja1.projectohibrido.usuario.entity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "usuario")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_usuario")
    private Integer idUsuario;

    @Column(name = "nome", nullable = false, length = 100)
    private String nome;

    @Column(name = "apelido", nullable = false, length = 100)
    private String apelido;

    @Column(name = "email", nullable = false, unique = true, length = 100)
    private String email;

    @Column(name = "senha_hash", nullable = false, length = 255)
    private String senhaHash;

    @Column(name = "telefone", length = 20)
    private String telefone;

    @Column(name = "ativo")
    private Integer ativo = 1;

    @CreationTimestamp
    @Column(name = "data_cadastro", nullable = false, updatable = false)
    private LocalDateTime dataCadastro;

    @Column(name = "idprovincia")
    private Integer idProvincia;

    @Column(name = "idcidade")
    private Integer idCidade;

    @Column(name = "idperfil")
    private Integer idPerfil;

    @Column(name = "primeira_senha")
    private Integer primeiraSenha = 1;

    // Métodos auxiliares
    public boolean isAtivo() {
        return this.ativo != null && this.ativo == 1;
    }

    public void ativar() {
        this.ativo = 1;
    }

    public void desativar() {
        this.ativo = 0;
    }

    public void toggleStatus() {
        this.ativo = (this.ativo == 1) ? 0 : 1;
    }
}
