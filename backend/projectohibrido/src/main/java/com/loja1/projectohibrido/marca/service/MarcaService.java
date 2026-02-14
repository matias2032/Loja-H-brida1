package com.loja1.projectohibrido.marca.service;

import com.loja1.projectohibrido.marca.dto.MarcaRequestDTO;
import com.loja1.projectohibrido.marca.dto.MarcaResponseDTO;
import com.loja1.projectohibrido.marca.entity.Marca;
import com.loja1.projectohibrido.marca.repository.MarcaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MarcaService {
    
    private final MarcaRepository marcaRepository;
    
    // ===== CRUD BÁSICO =====
    
    @Transactional
    public MarcaResponseDTO criar(MarcaRequestDTO dto) {
        log.info("Criando nova marca: {}", dto.getNomeMarca());
        
        Marca marca = new Marca();
        marca.setNomeMarca(dto.getNomeMarca());
        
        Marca marcaSalva = marcaRepository.save(marca);
        log.info("Marca criada com ID: {}", marcaSalva.getIdMarca());
        
        return mapToResponseDTO(marcaSalva);
    }
    
    @Transactional
    public MarcaResponseDTO atualizar(Integer id, MarcaRequestDTO dto) {
        log.info("Atualizando marca ID: {}", id);
        
        Marca marca = marcaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Marca não encontrada com ID: " + id));
        
        marca.setNomeMarca(dto.getNomeMarca());
        
        Marca marcaAtualizada = marcaRepository.save(marca);
        log.info("Marca atualizada: {}", marcaAtualizada.getIdMarca());
        
        return mapToResponseDTO(marcaAtualizada);
    }
    
    @Transactional
    public void deletar(Integer id) {
        log.info("Deletando marca ID: {}", id);
        
        if (!marcaRepository.existsById(id)) {
            throw new RuntimeException("Marca não encontrada com ID: " + id);
        }
        
        marcaRepository.deleteById(id);
        log.info("Marca deletada com sucesso: {}", id);
    }
    
    @Transactional(readOnly = true)
    public List<MarcaResponseDTO> listar() {
        log.info("Listando todas as marcas");
        return marcaRepository.findAll().stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }
    
    @Transactional(readOnly = true)
    public MarcaResponseDTO buscarPorId(Integer id) {
        log.info("Buscando marca por ID: {}", id);
        Marca marca = marcaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Marca não encontrada com ID: " + id));
        return mapToResponseDTO(marca);
    }
    
    // ===== MÉTODOS AUXILIARES =====
    
    private MarcaResponseDTO mapToResponseDTO(Marca marca) {
        MarcaResponseDTO dto = new MarcaResponseDTO();
        dto.setIdMarca(marca.getIdMarca());
        dto.setNomeMarca(marca.getNomeMarca());
        return dto;
    }
}