package com.ainovel.server.repository;

import java.time.LocalDateTime;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.ReactiveMongoRepository;
import org.springframework.stereotype.Repository;

import com.ainovel.server.domain.model.analytics.WritingEvent;

import reactor.core.publisher.Flux;

@Repository
public interface WritingEventRepository extends ReactiveMongoRepository<WritingEvent, String> {

    Flux<WritingEvent> findByUserIdOrderByTimestampDesc(String userId, Pageable pageable);

    Flux<WritingEvent> findByNovelIdOrderByTimestampDesc(String novelId, Pageable pageable);

    Flux<WritingEvent> findBySceneIdOrderByTimestampDesc(String sceneId, Pageable pageable);

    Flux<WritingEvent> findByUserIdAndTimestampBetweenOrderByTimestampDesc(
        String userId, LocalDateTime start, LocalDateTime end, Pageable pageable);
}


