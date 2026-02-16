package com.loja1.projectohibrido.produto.service;

import com.loja1.projectohibrido.categoria.repository.ProdutoCategoriaRepository;
import com.loja1.projectohibrido.categoria.entity.ProdutoCategoria;
import com.loja1.projectohibrido.produto.dto.ProdutoImagemRequestDTO;
import com.loja1.projectohibrido.produto.dto.ProdutoRequestDTO;
import com.loja1.projectohibrido.produto.dto.ProdutoResponseDTO;
import com.loja1.projectohibrido.produto.entity.Produto;
import com.loja1.projectohibrido.produto.entity.ProdutoImagem;
import com.loja1.projectohibrido.produto.entity.ProdutoMarca;
import com.loja1.projectohibrido.produto.repository.ProdutoImagemRepository;
import com.loja1.projectohibrido.produto.repository.ProdutoRepository;
import com.loja1.projectohibrido.produto.repository.ProdutoMarcaRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProdutoService {
    
    private final ProdutoRepository produtoRepository;
    private final ProdutoCategoriaRepository produtoCategoriaRepository;
    private final ProdutoImagemRepository produtoImagemRepository;
    private final ProdutoMarcaRepository produtoMarcaRepository; 

    // ===== CRUD BÁSICO =====
    
    @Transactional
public ProdutoResponseDTO criar(ProdutoRequestDTO dto) {
    log.info("Criando novo produto: {}", dto.getNomeProduto());
    
    Produto produto = new Produto();
    produto.setNomeProduto(dto.getNomeProduto());
    produto.setDescricao(dto.getDescricao());
    produto.setPreco(dto.getPreco());
    produto.setQuantidadeEstoque(dto.getQuantidadeEstoque());
    produto.setPrecoPromocional(dto.getPrecoPromocional());
    
    Produto produtoSalvo = produtoRepository.save(produto);
    log.info("Produto criado com ID: {}", produtoSalvo.getIdProduto());
    
    // Associar categorias se fornecidas
    if (dto.getCategorias() != null && !dto.getCategorias().isEmpty()) {
        associarCategorias(produtoSalvo.getIdProduto(), dto.getCategorias());
    }
    
    // ✅ ADICIONE: Associar marcas se fornecidas
    if (dto.getMarcas() != null && !dto.getMarcas().isEmpty()) {
        associarMarcas(produtoSalvo.getIdProduto(), dto.getMarcas());
    }
    
    return mapToResponseDTO(produtoSalvo);
}

@Transactional
public ProdutoResponseDTO atualizar(Integer id, ProdutoRequestDTO dto) {
    log.info("Atualizando produto ID: {}", id);
    
    Produto produto = produtoRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Produto não encontrado com ID: " + id));
    
    produto.setNomeProduto(dto.getNomeProduto());
    produto.setDescricao(dto.getDescricao());
    produto.setPreco(dto.getPreco());
    produto.setQuantidadeEstoque(dto.getQuantidadeEstoque());
    produto.setPrecoPromocional(dto.getPrecoPromocional());
    
    Produto produtoAtualizado = produtoRepository.save(produto);
    
    // Atualizar categorias: remover antigas e adicionar novas
    if (dto.getCategorias() != null) {
        removerTodasCategorias(id);
        associarCategorias(id, dto.getCategorias());
    }
    
    // ✅ ADICIONE: Atualizar marcas: remover antigas e adicionar novas
    if (dto.getMarcas() != null) {
        removerTodasMarcas(id);
        associarMarcas(id, dto.getMarcas());
    }
    
    log.info("Produto atualizado: {}", produtoAtualizado.getIdProduto());
    return mapToResponseDTO(produtoAtualizado);
}

// ✅ ADICIONE ESTES MÉTODOS AUXILIARES:

private void associarMarcas(Integer idProduto, List<Integer> marcas) {
    marcas.forEach(idMarca -> associarMarca(idProduto, idMarca));
}

private void removerTodasMarcas(Integer idProduto) {
    List<ProdutoMarca> associacoes = produtoMarcaRepository.findByIdProduto(idProduto);
    associacoes.forEach(assoc -> 
        produtoMarcaRepository.deleteByIdMarcaAndIdProduto(assoc.getIdMarca(), idProduto)
    );
}
    
@Transactional
public void toggleAtivo(Integer id) {
    log.info("Alternando status de ativação do produto ID: {}", id);
    
    Produto produto = produtoRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Produto não encontrado com ID: " + id));
    
    // ✅ MUDANÇA: Comparação com Short
    produto.setAtivo(produto.getAtivo() == 1 ? (short) 0 : (short) 1);
    produtoRepository.save(produto);
    
    log.info("Produto ID {} agora está: {}", id, produto.getAtivo() == 1 ? "ATIVO" : "INATIVO");
}
    
    @Transactional(readOnly = true)
    public List<ProdutoResponseDTO> listar() {
        log.info("Listando todos os produtos");
        return produtoRepository.findAll().stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }
    
@Transactional(readOnly = true)
public List<ProdutoResponseDTO> listarAtivos() {
    log.info("Listando produtos ativos");
    // ✅ MUDANÇA: passar (short) 1
    return produtoRepository.findByAtivo((short) 1).stream()
            .map(this::mapToResponseDTO)
            .collect(Collectors.toList());
}
    
    @Transactional(readOnly = true)
    public ProdutoResponseDTO buscarPorId(Integer id) {
        log.info("Buscando produto por ID: {}", id);
        Produto produto = produtoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Produto não encontrado com ID: " + id));
        return mapToResponseDTO(produto);
    }
    
    // ===== ASSOCIAÇÕES COM CATEGORIAS =====
    
    @Transactional
    public void associarCategoria(Integer idProduto, Integer idCategoria) {
        log.info("Associando categoria {} ao produto {}", idCategoria, idProduto);
        
        if (!produtoRepository.existsById(idProduto)) {
            throw new RuntimeException("Produto não encontrado com ID: " + idProduto);
        }
        
        if (produtoCategoriaRepository.existsByIdCategoriaAndIdProduto(idCategoria, idProduto)) {
            log.warn("Associação já existe entre produto {} e categoria {}", idProduto, idCategoria);
            return;
        }
        
        ProdutoCategoria pc = new ProdutoCategoria();
        pc.setIdProduto(idProduto);
        pc.setIdCategoria(idCategoria);
        produtoCategoriaRepository.save(pc);
        
        log.info("Categoria {} associada ao produto {} com sucesso", idCategoria, idProduto);
    }
    
    @Transactional
    public void desassociarCategoria(Integer idProduto, Integer idCategoria) {
        log.info("Desassociando categoria {} do produto {}", idCategoria, idProduto);
        produtoCategoriaRepository.deleteByIdCategoriaAndIdProduto(idCategoria, idProduto);
        log.info("Categoria {} desassociada do produto {} com sucesso", idCategoria, idProduto);
    }
    
    private void associarCategorias(Integer idProduto, List<Integer> categorias) {
        categorias.forEach(idCategoria -> associarCategoria(idProduto, idCategoria));
    }
    
    private void removerTodasCategorias(Integer idProduto) {
        List<ProdutoCategoria> associacoes = produtoCategoriaRepository.findByIdProduto(idProduto);
        associacoes.forEach(assoc -> 
            produtoCategoriaRepository.deleteByIdCategoriaAndIdProduto(assoc.getIdCategoria(), idProduto)
        );
    }
    
    @Transactional(readOnly = true)
    public List<Integer> listarCategoriasDoProduto(Integer idProduto) {
        log.info("Listando categorias do produto: {}", idProduto);
        return produtoCategoriaRepository.findByIdProduto(idProduto)
                .stream()
                .map(ProdutoCategoria::getIdCategoria)
                .collect(Collectors.toList());
    }
    
    // ===== GESTÃO DE IMAGENS =====
    
    @Transactional
public void adicionarImagem(Integer idProduto, ProdutoImagemRequestDTO dto) {
    log.info("Adicionando imagem ao produto ID: {}", idProduto);
    
    if (!produtoRepository.existsById(idProduto)) {
        throw new RuntimeException("Produto não encontrado com ID: " + idProduto);
    }
    
    // ✅ MUDANÇA: comparação com Short
    if (dto.getImagemPrincipal() != null && dto.getImagemPrincipal() == 1) {
        produtoImagemRepository.desmarcarTodasImagensPrincipais(idProduto);
    }
    
    ProdutoImagem imagem = new ProdutoImagem();
    imagem.setIdProduto(idProduto);
    imagem.setCaminhoImagem(dto.getCaminhoImagem());
    imagem.setLegenda(dto.getLegenda());
    
    // ✅ MUDANÇA: cast para Short
    imagem.setImagemPrincipal(dto.getImagemPrincipal() != null ? dto.getImagemPrincipal() : (short) 0);
    
    produtoImagemRepository.save(imagem);
    log.info("Imagem adicionada ao produto {} com sucesso", idProduto);
}

@Transactional
public void alterarImagemPrincipal(Integer idProduto, Integer idImagem) {
    log.info("Alterando imagem principal do produto {} para imagem ID: {}", idProduto, idImagem);
    
    ProdutoImagem imagem = produtoImagemRepository.findById(idImagem)
            .orElseThrow(() -> new RuntimeException("Imagem não encontrada com ID: " + idImagem));
    
    if (!imagem.getIdProduto().equals(idProduto)) {
        throw new RuntimeException("A imagem não pertence ao produto informado");
    }
    
    produtoImagemRepository.desmarcarTodasImagensPrincipais(idProduto);
    
    // ✅ MUDANÇA: cast para Short
    imagem.setImagemPrincipal((short) 1);
    produtoImagemRepository.save(imagem);
    
    log.info("Imagem principal do produto {} alterada com sucesso", idProduto);
}

@Transactional
public void removerImagem(Integer idImagem) {
    log.info("Removendo imagem ID: {}", idImagem);
    produtoImagemRepository.deleteById(idImagem);
    log.info("Imagem {} removida com sucesso", idImagem);
}

@Transactional(readOnly = true)
public List<ProdutoImagem> listarImagensDoProduto(Integer idProduto) {
    log.info("Listando imagens do produto: {}", idProduto);
    return produtoImagemRepository.findByIdProduto(idProduto);
}

// No mapToResponseDTO:
private ProdutoResponseDTO mapToResponseDTO(Produto produto) {
    ProdutoResponseDTO dto = new ProdutoResponseDTO();
    dto.setIdProduto(produto.getIdProduto());
    dto.setNomeProduto(produto.getNomeProduto());
    dto.setDescricao(produto.getDescricao());
    dto.setPreco(produto.getPreco());
    dto.setQuantidadeEstoque(produto.getQuantidadeEstoque());
    dto.setPrecoPromocional(produto.getPrecoPromocional());
    dto.setAtivo(produto.getAtivo());
    dto.setDataCadastro(produto.getDataCadastro());
    
    // Buscar categorias associadas
    List<Integer> categorias = listarCategoriasDoProduto(produto.getIdProduto());
    dto.setCategorias(categorias);
    
    // ✅ ADICIONE ESTAS LINHAS: Buscar marcas associadas
    List<Integer> marcas = listarMarcasDoProduto(produto.getIdProduto());
    dto.setMarcas(marcas);
    
    // Buscar imagem principal
    produtoImagemRepository.findByIdProdutoAndImagemPrincipal(produto.getIdProduto(), (short) 1)
            .ifPresent(img -> dto.setImagemPrincipalUrl(img.getCaminhoImagem()));
    
    return dto;
}

// ===== ASSOCIAÇÕES COM MARCAS =====

@Transactional
public void associarMarca(Integer idProduto, Integer idMarca) {
    log.info("Associando marca {} ao produto {}", idMarca, idProduto);
    
    if (!produtoRepository.existsById(idProduto)) {
        throw new RuntimeException("Produto não encontrado com ID: " + idProduto);
    }
    
    if (produtoMarcaRepository.existsByIdMarcaAndIdProduto(idMarca, idProduto)) {
        log.warn("Associação já existe entre produto {} e marca {}", idProduto, idMarca);
        return;
    }
    
    ProdutoMarca pm = new ProdutoMarca();
    pm.setIdProduto(idProduto);
    pm.setIdMarca(idMarca);
    produtoMarcaRepository.save(pm);
    
    log.info("Marca {} associada ao produto {} com sucesso", idMarca, idProduto);
}

@Transactional
public void desassociarMarca(Integer idProduto, Integer idMarca) {
    log.info("Desassociando marca {} do produto {}", idMarca, idProduto);
    produtoMarcaRepository.deleteByIdMarcaAndIdProduto(idMarca, idProduto);
    log.info("Marca {} desassociada do produto {} com sucesso", idMarca, idProduto);
}

@Transactional(readOnly = true)
public List<Integer> listarMarcasDoProduto(Integer idProduto) {
    log.info("Listando marcas do produto: {}", idProduto);
    return produtoMarcaRepository.findByIdProduto(idProduto)
            .stream()
            .map(ProdutoMarca::getIdMarca)
            .collect(Collectors.toList());
}

@Transactional(readOnly = true)
public List<Integer> listarProdutosDaMarca(Integer idMarca) {
    log.info("Listando produtos da marca: {}", idMarca);
    return produtoMarcaRepository.findByIdMarca(idMarca)
            .stream()
            .map(ProdutoMarca::getIdProduto)
            .collect(Collectors.toList());
}
}