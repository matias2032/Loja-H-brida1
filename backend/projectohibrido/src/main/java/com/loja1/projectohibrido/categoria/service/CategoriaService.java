package com.loja1.projectohibrido.categoria.service;

import com.loja1.projectohibrido.categoria.dto.CategoriaRequestDTO;
import com.loja1.projectohibrido.categoria.dto.CategoriaResponseDTO;
import com.loja1.projectohibrido.categoria.entity.Categoria;
import com.loja1.projectohibrido.categoria.entity.CategoriaMarca;
import com.loja1.projectohibrido.categoria.entity.ProdutoCategoria;
import com.loja1.projectohibrido.categoria.repository.CategoriaMarcaRepository;
import com.loja1.projectohibrido.categoria.repository.CategoriaRepository;
import com.loja1.projectohibrido.categoria.repository.ProdutoCategoriaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoriaService {
    
    private final CategoriaRepository categoriaRepository;
    private final ProdutoCategoriaRepository produtoCategoriaRepository;
    private final CategoriaMarcaRepository categoriaMarcaRepository;
    
    // ===== CRUD BÁSICO =====
    
    @Transactional
    public CategoriaResponseDTO criar(CategoriaRequestDTO dto) {
        log.info("Criando nova categoria: {}", dto.getNomeCategoria());
        
        Categoria categoria = new Categoria();
        categoria.setNomeCategoria(dto.getNomeCategoria());
        categoria.setDescricao(dto.getDescricao());
        
        Categoria categoriaSalva = categoriaRepository.save(categoria);
        log.info("Categoria criada com ID: {}", categoriaSalva.getIdCategoria());
        
        return mapToResponseDTO(categoriaSalva);
    }
    
    @Transactional
    public CategoriaResponseDTO atualizar(Integer id, CategoriaRequestDTO dto) {
        log.info("Atualizando categoria ID: {}", id);
        
        Categoria categoria = categoriaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Categoria não encontrada com ID: " + id));
        
        categoria.setNomeCategoria(dto.getNomeCategoria());
        categoria.setDescricao(dto.getDescricao());
        
        Categoria categoriaAtualizada = categoriaRepository.save(categoria);
        log.info("Categoria atualizada: {}", categoriaAtualizada.getIdCategoria());
        
        return mapToResponseDTO(categoriaAtualizada);
    }
    
    @Transactional
    public void deletar(Integer id) {
        log.info("Deletando categoria ID: {}", id);
        
        if (!categoriaRepository.existsById(id)) {
            throw new RuntimeException("Categoria não encontrada com ID: " + id);
        }
        
        categoriaRepository.deleteById(id);
        log.info("Categoria deletada com sucesso: {}", id);
    }
    
    @Transactional(readOnly = true)
    public List<CategoriaResponseDTO> listar() {
        log.info("Listando todas as categorias");
        return categoriaRepository.findAll().stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public CategoriaResponseDTO buscarPorId(Integer id) {
        log.info("Buscando categoria por ID: {}", id);
        Categoria categoria = categoriaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Categoria não encontrada com ID: " + id));
        return mapToResponseDTO(categoria);
    }
    
    // ===== ASSOCIAÇÕES COM PRODUTOS =====
    
    @Transactional
    public void associarProduto(Integer idCategoria, Integer idProduto) {
        log.info("Associando produto {} à categoria {}", idProduto, idCategoria);
        
        // Verificar se a categoria existe
        if (!categoriaRepository.existsById(idCategoria)) {
            throw new RuntimeException("Categoria não encontrada com ID: " + idCategoria);
        }
        
        // Verificar se já existe a associação
        if (produtoCategoriaRepository.existsByIdCategoriaAndIdProduto(idCategoria, idProduto)) {
            log.warn("Associação já existe entre categoria {} e produto {}", idCategoria, idProduto);
            return;
        }
        
        ProdutoCategoria pc = new ProdutoCategoria();
        pc.setIdCategoria(idCategoria);
        pc.setIdProduto(idProduto);
        produtoCategoriaRepository.save(pc);
        
        log.info("Produto {} associado à categoria {} com sucesso", idProduto, idCategoria);
    }
    
    @Transactional
    public void desassociarProduto(Integer idCategoria, Integer idProduto) {
        log.info("Desassociando produto {} da categoria {}", idProduto, idCategoria);
        produtoCategoriaRepository.deleteByIdCategoriaAndIdProduto(idCategoria, idProduto);
        log.info("Produto {} desassociado da categoria {} com sucesso", idProduto, idCategoria);
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarProdutosDaCategoria(Integer idCategoria) {
        log.info("Listando produtos da categoria: {}", idCategoria);
        return produtoCategoriaRepository.findByIdCategoria(idCategoria)
                .stream()
                .map(ProdutoCategoria::getIdProduto)
                .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarCategoriasDoProduto(Integer idProduto) {
        log.info("Listando categorias do produto: {}", idProduto);
        return produtoCategoriaRepository.findByIdProduto(idProduto)
                .stream()
                .map(ProdutoCategoria::getIdCategoria)
                .collect(Collectors.toList());
    }
    
    // ===== ASSOCIAÇÕES COM MARCAS =====
    
    @Transactional
    public void associarMarca(Integer idCategoria, Integer idMarca) {
        log.info("Associando marca {} à categoria {}", idMarca, idCategoria);
        
        // Verificar se a categoria existe
        if (!categoriaRepository.existsById(idCategoria)) {
            throw new RuntimeException("Categoria não encontrada com ID: " + idCategoria);
        }
        
        // Verificar se já existe a associação
        if (categoriaMarcaRepository.existsByIdCategoriaAndIdMarca(idCategoria, idMarca)) {
            log.warn("Associação já existe entre categoria {} e marca {}", idCategoria, idMarca);
            return;
        }
        
        CategoriaMarca cm = new CategoriaMarca();
        cm.setIdCategoria(idCategoria);
        cm.setIdMarca(idMarca);
        categoriaMarcaRepository.save(cm);
        
        log.info("Marca {} associada à categoria {} com sucesso", idMarca, idCategoria);
    }
    
    @Transactional
    public void desassociarMarca(Integer idCategoria, Integer idMarca) {
        log.info("Desassociando marca {} da categoria {}", idMarca, idCategoria);
        categoriaMarcaRepository.deleteByIdCategoriaAndIdMarca(idCategoria, idMarca);
        log.info("Marca {} desassociada da categoria {} com sucesso", idMarca, idCategoria);
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarMarcasDaCategoria(Integer idCategoria) {
        log.info("Listando marcas da categoria: {}", idCategoria);
        return categoriaMarcaRepository.findByIdCategoria(idCategoria)
                .stream()
                .map(CategoriaMarca::getIdMarca)
                .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarCategoriasDaMarca(Integer idMarca) {
        log.info("Listando categorias da marca: {}", idMarca);
        return categoriaMarcaRepository.findByIdMarca(idMarca)
                .stream()
                .map(CategoriaMarca::getIdCategoria)
                .collect(Collectors.toList());
    }
    
    // ===== MÉTODOS AUXILIARES =====
    
    private CategoriaResponseDTO mapToResponseDTO(Categoria categoria) {
        CategoriaResponseDTO dto = new CategoriaResponseDTO();
        dto.setIdCategoria(categoria.getIdCategoria());
        dto.setNomeCategoria(categoria.getNomeCategoria());
        dto.setDescricao(categoria.getDescricao());
        return dto;
    }
}