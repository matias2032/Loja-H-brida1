package com.loja1.projectohibrido.usuario.repository;

import com.loja1.projectohibrido.usuario.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {

    /**
     * Busca usuário por email
     */
    Optional<Usuario> findByEmail(String email);

    /**
     * Verifica se existe usuário com o email informado
     */
    boolean existsByEmail(String email);

    /**
     * Lista todos os usuários EXCETO os administradores (idperfil = 1)
     * Regra de Negócio: Gerentes não podem visualizar/gerenciar admins
     */
    @Query("SELECT u FROM Usuario u WHERE u.idPerfil != 1")
    List<Usuario> findAllExceptAdmins();

    /**
     * Busca usuários por perfil (exceto admins)
     */
    @Query("SELECT u FROM Usuario u WHERE u.idPerfil = :idPerfil AND u.idPerfil != 1")
    List<Usuario> findByPerfilExceptAdmins(@Param("idPerfil") Integer idPerfil);

    /**
     * Busca usuários por status ativo (exceto admins)
     */
    @Query("SELECT u FROM Usuario u WHERE u.ativo = :ativo AND u.idPerfil != 1")
    List<Usuario> findByAtivoExceptAdmins(@Param("ativo") Integer ativo);

    /**
     * Busca usuários por perfil E status (exceto admins)
     */
    @Query("SELECT u FROM Usuario u WHERE u.idPerfil = :idPerfil AND u.ativo = :ativo AND u.idPerfil != 1")
    List<Usuario> findByPerfilAndAtivoExceptAdmins(
            @Param("idPerfil") Integer idPerfil, 
            @Param("ativo") Integer ativo
    );

    @Query("SELECT u FROM Usuario u WHERE u.email = :c OR u.telefone = :c OR u.apelido = :c")
Optional<Usuario> findByEmailOrTelefoneOrApelido(@Param("c") String credencial);

    /**
     * Conta quantos usuários ativos existem
     */
    long countByAtivo(Integer ativo);

    /**
     * Conta quantos usuários existem por perfil
     */
    long countByIdPerfil(Integer idPerfil);
}