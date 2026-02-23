package com.loja1.projectohibrido.carrinho.repository;

import com.loja1.projectohibrido.carrinho.entity.Carrinho;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CarrinhoRepository extends JpaRepository<Carrinho, Integer> {

    // ── Buscas por utilizador autenticado ─────────────────────────────────────

    Optional<Carrinho> findByIdUsuarioAndStatus(Integer idUsuario, String status);

    /**
     * Busca o carrinho activo do utilizador com os itens já carregados em
     * memória (JOIN FETCH), evitando N+1 queries ao iterar os itens.
     */
    @Query("""
            SELECT c FROM Carrinho c
            LEFT JOIN FETCH c.itens i
            LEFT JOIN FETCH i.produto
            WHERE c.idUsuario = :idUsuario
              AND c.status = :status
            """)
    Optional<Carrinho> findByIdUsuarioAndStatusWithItens(
            @Param("idUsuario") Integer idUsuario,
            @Param("status") String status);

    // ── Buscas por carrinho guest (session_id) ────────────────────────────────

    Optional<Carrinho> findBySessionIdAndStatus(String sessionId, String status);

    @Query("""
            SELECT c FROM Carrinho c
            LEFT JOIN FETCH c.itens i
            LEFT JOIN FETCH i.produto
            WHERE c.sessionId = :sessionId
              AND c.status = :status
            """)
    Optional<Carrinho> findBySessionIdAndStatusWithItens(
            @Param("sessionId") String sessionId,
            @Param("status") String status);

    // ── Busca por id com itens (usada na conversão para pedido) ──────────────

    @Query("""
            SELECT c FROM Carrinho c
            LEFT JOIN FETCH c.itens i
            LEFT JOIN FETCH i.produto
            WHERE c.idCarrinho = :idCarrinho
            """)
    Optional<Carrinho> findByIdWithItens(@Param("idCarrinho") Integer idCarrinho);

    /**
     * Busca com lock pessimista — utilizada na conversão para pedido para
     * garantir que nenhuma outra transacção paralela modifique o mesmo
     * carrinho enquanto o pedido está a ser criado.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM Carrinho c WHERE c.idCarrinho = :idCarrinho")
    Optional<Carrinho> findByIdWithLock(@Param("idCarrinho") Integer idCarrinho);

    // ── Verificações de existência ────────────────────────────────────────────

    boolean existsByIdUsuarioAndStatus(Integer idUsuario, String status);

    boolean existsBySessionIdAndStatus(String sessionId, String status);
}