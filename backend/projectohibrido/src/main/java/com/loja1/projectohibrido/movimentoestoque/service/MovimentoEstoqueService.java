package com.loja1.projectohibrido.movimentoestoque.service;

import com.loja1.projectohibrido.movimentoestoque.dto.MovimentoEstoqueRequestDTO;
import com.loja1.projectohibrido.movimentoestoque.dto.MovimentoEstoqueResponseDTO;
import com.loja1.projectohibrido.movimentoestoque.entity.MovimentoEstoque;
import com.loja1.projectohibrido.movimentoestoque.repository.MovimentoEstoqueRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.loja1.projectohibrido.produto.repository.ProdutoRepository;
import com.loja1.projectohibrido.usuario.repository.UsuarioRepository; // ajuste o package ao seu projeto

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MovimentoEstoqueService {

    private final MovimentoEstoqueRepository repository;
private final ProdutoRepository produtoRepository;
private final UsuarioRepository usuarioRepository;


    @Transactional
    public MovimentoEstoqueResponseDTO registrar(MovimentoEstoqueRequestDTO dto) {
        log.info("📦 Registrando movimento de estoque | produto={} tipo={} qtdAnterior={} qtdNova={}",
                dto.getIdProduto(), dto.getTipoMovimento(),
                dto.getQuantidadeAnterior(), dto.getQuantidadeNova());

        MovimentoEstoque movimento = new MovimentoEstoque();
        movimento.setIdProduto(dto.getIdProduto());
        movimento.setIdUsuario(dto.getIdUsuario());
        movimento.setTipoMovimento(dto.getTipoMovimento());
        movimento.setQuantidade(dto.getQuantidade());
        movimento.setQuantidadeAnterior(dto.getQuantidadeAnterior());
        movimento.setQuantidadeNova(dto.getQuantidadeNova());
        movimento.setMotivo(dto.getMotivo());

        MovimentoEstoque salvo = repository.save(movimento);
        log.info("✅ Movimento registrado | id={}", salvo.getIdMovimento());

        return mapToDTO(salvo);
    }

    @Transactional(readOnly = true)
    public List<MovimentoEstoqueResponseDTO> listarPorProduto(Integer idProduto) {
        log.info("🔍 Buscando movimentos do produto={}", idProduto);
        return repository.findByIdProdutoOrderByDataMovimentoDesc(idProduto)
                .stream().map(this::mapToDTO).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
public List<MovimentoEstoqueResponseDTO> listarTodos() {
    log.info("🔍 Listando todos os movimentos de estoque");
    return repository.findAllByOrderByDataMovimentoDesc()
            .stream().map(this::mapToDTO).collect(Collectors.toList());
}

@Transactional(readOnly = true)
public List<MovimentoEstoqueResponseDTO> listarPorPeriodo(LocalDateTime inicio, LocalDateTime fim) {
    log.info("🔍 Listando movimentos entre {} e {}", inicio, fim);
    return repository.findByPeriodo(inicio, fim)
            .stream().map(this::mapToDTO).collect(Collectors.toList());
}

 private MovimentoEstoqueResponseDTO mapToDTO(MovimentoEstoque m) {
    MovimentoEstoqueResponseDTO dto = new MovimentoEstoqueResponseDTO();
    dto.setIdMovimento(m.getIdMovimento());
    dto.setIdProduto(m.getIdProduto());
    dto.setIdUsuario(m.getIdUsuario());
    dto.setTipoMovimento(m.getTipoMovimento());
    dto.setQuantidade(m.getQuantidade());
    dto.setQuantidadeAnterior(m.getQuantidadeAnterior());
    dto.setQuantidadeNova(m.getQuantidadeNova());
    dto.setMotivo(m.getMotivo());
    dto.setDataMovimento(m.getDataMovimento());

    // ── Nome do produto ──
    produtoRepository.findById(m.getIdProduto())
            .ifPresentOrElse(
                p -> dto.setNomeProduto(p.getNomeProduto()),
                () -> dto.setNomeProduto("Produto #" + m.getIdProduto())
            );

    // ── Nome do usuário (nome + apelido) ──
    usuarioRepository.findById(m.getIdUsuario())
            .ifPresentOrElse(
                u -> dto.setNomeUsuario(u.getNome() + " " + u.getApelido()),
                () -> dto.setNomeUsuario("Usuário #" + m.getIdUsuario())
            );

    return dto;
}
}