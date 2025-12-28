package com.ainovel.server.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.ainovel.server.service.vectorstore.VectorStore;
import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.store.embedding.EmbeddingStore;
import dev.langchain4j.store.embedding.inmemory.InMemoryEmbeddingStore;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;

/**
 * Fallback configuration when Chroma is disabled.
 */
@Configuration
@ConditionalOnProperty(name = "vectorstore.chroma.enabled", havingValue = "false")
public class VectorStoreFallbackConfig {

    // Provide a no-op VectorStore to satisfy business services depending on our interface
    @Bean
    public VectorStore noopVectorStore() {
        return new VectorStore() {
            @Override
            public Mono<String> storeVector(String content, float[] vector, Map<String, Object> metadata) {
                return Mono.error(new UnsupportedOperationException("VectorStore disabled by configuration"));
            }

            @Override
            public Mono<List<String>> storeVectorsBatch(List<VectorData> vectorDataList) {
                return Mono.error(new UnsupportedOperationException("VectorStore disabled by configuration"));
            }

            @Override
            public Mono<String> storeKnowledgeChunk(com.ainovel.server.domain.model.KnowledgeChunk chunk) {
                return Mono.error(new UnsupportedOperationException("VectorStore disabled by configuration"));
            }

            @Override
            public Flux<com.ainovel.server.service.vectorstore.SearchResult> search(float[] queryVector, int limit) {
                return Flux.empty();
            }

            @Override
            public Flux<com.ainovel.server.service.vectorstore.SearchResult> search(float[] queryVector, Map<String, Object> filter, int limit) {
                return Flux.empty();
            }

            @Override
            public Flux<com.ainovel.server.service.vectorstore.SearchResult> searchByNovelId(float[] queryVector, String novelId, int limit) {
                return Flux.empty();
            }

            @Override
            public Mono<Void> deleteByNovelId(String novelId) {
                return Mono.empty();
            }

            @Override
            public Mono<Void> deleteBySourceId(String novelId, String sourceType, String sourceId) {
                return Mono.empty();
            }
        };
    }

    // Provide a minimal EmbeddingStore so RagConfig can still build ContentRetriever without Chroma
    @Bean
    public EmbeddingStore<TextSegment> fallbackEmbeddingStore() {
        return new InMemoryEmbeddingStore<>();
    }
}


