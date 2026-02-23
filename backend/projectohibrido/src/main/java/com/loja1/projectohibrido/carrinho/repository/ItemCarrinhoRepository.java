package com.loja1.projectohibrido.carrinho.repository;

import com.loja1.projectohibrido.carrinho.entity.ItemCarrinho;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ItemCarrinhoRepository extends JpaRepository<ItemCarrinho, Integer> {

    // ── Buscas por carrinho ───────────────────────────────────────────────────

    List<ItemCarrinho> findByCarrinhoIdCarrinho(Integer idCarrinho);

    /**
     * Busca um item específico dentro de um carrinho pelo produto.
     * Usado para verificar duplicidade antes de adicionar e para atualizar
     * a quantidade de um item já existente.
     */
    @Query("""
            SELECT i FROM ItemCarrinho i
            WHERE i.carrinho.idCarrinho = :idCarrinho
              AND i.produto.idProduto   = :idProduto
            """)
    Optional<ItemCarrinho> findByCarrinhoAndProduto(
            @Param("idCarrinho") Integer idCarrinho,
            @Param("idProduto") Integer idProduto);

    // ── Contagem ──────────────────────────────────────────────────────────────

    /**
     * Retorna o número de itens distintos no carrinho.
     * Usado na Regra 4: se após remoção o count for 0, o carrinho é eliminado.
     */
    long countByCarrinhoIdCarrinho(Integer idCarrinho);

    // ── Remoções ──────────────────────────────────────────────────────────────

    /**
     * Remove um item específico do carrinho sem precisar carregá-lo em memória.
     * Mais eficiente que carregar a entidade e chamar delete().
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            DELETE FROM ItemCarrinho i
            WHERE i.carrinho.idCarrinho = :idCarrinho
              AND i.produto.idProduto   = :idProduto
            """)
    int deleteByCarrinhoAndProduto(
            @Param("idCarrinho") Integer idCarrinho,
            @Param("idProduto") Integer idProduto);

    /**
     * Remove todos os itens de um carrinho.
     * Usado ao esvaziar o carrinho manualmente ou ao eliminar o carrinho inteiro.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM ItemCarrinho i WHERE i.carrinho.idCarrinho = :idCarrinho")
    void deleteAllByCarrinhoId(@Param("idCarrinho") Integer idCarrinho);

    // ── Verificação de existência ─────────────────────────────────────────────

    boolean existsByCarrinhoIdCarrinhoAndProdutoIdProduto(Integer idCarrinho, Integer idProduto);
}